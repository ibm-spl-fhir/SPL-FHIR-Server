package ca.uhn.fhir.jpa.starter;

import static ca.uhn.fhir.util.TestUtil.waitForSize;
import static org.junit.Assert.assertEquals;

import java.io.IOException;
import java.net.URI;
import java.nio.file.Paths;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import ca.uhn.fhir.rest.api.CacheControlDirective;
import ca.uhn.fhir.rest.api.EncodingEnum;
import ca.uhn.fhir.rest.api.MethodOutcome;
import ca.uhn.fhir.util.PortUtil;
import org.eclipse.jetty.server.Server;
import org.eclipse.jetty.webapp.WebAppContext;
import org.eclipse.jetty.websocket.api.Session;
import org.eclipse.jetty.websocket.client.ClientUpgradeRequest;
import org.eclipse.jetty.websocket.client.WebSocketClient;
import org.hl7.fhir.dstu3.model.Bundle;
import org.hl7.fhir.dstu3.model.Observation;
import org.hl7.fhir.dstu3.model.Patient;
import org.hl7.fhir.dstu3.model.Subscription;
import org.hl7.fhir.instance.model.api.IIdType;
import org.junit.*;

import ca.uhn.fhir.context.FhirContext;
import ca.uhn.fhir.rest.client.api.IGenericClient;
import ca.uhn.fhir.rest.client.api.ServerValidationModeEnum;
import ca.uhn.fhir.rest.client.interceptor.LoggingInterceptor;

public class ExampleServerDstu3IT {

	private static final org.slf4j.Logger ourLog = org.slf4j.LoggerFactory.getLogger(ExampleServerDstu3IT.class);
	private static IGenericClient ourClient;
	private static FhirContext ourCtx;
	private static int ourPort;

	private static Server ourServer;
	private static String ourServerBase;

	static {
		HapiProperties.forceReload();
		HapiProperties.setProperty(HapiProperties.FHIR_VERSION, "DSTU3");
		HapiProperties.setProperty(HapiProperties.DATASOURCE_URL, "jdbc:derby:memory:dbr3;create=true");
		HapiProperties.setProperty(HapiProperties.SUBSCRIPTION_WEBSOCKET_ENABLED, "true");
		ourCtx = FhirContext.forDstu3();
		ourPort = PortUtil.findFreePort();
	}

	@Test
	public void testCreateAndRead() {
		ourLog.info("Base URL is: " +  HapiProperties.getServerAddress());
		String methodName = "testCreateResourceConditional";

		Patient pt = new Patient();
		pt.addName().setFamily(methodName);
		IIdType id = ourClient.create().resource(pt).execute().getId();

		Patient pt2 = ourClient.read().resource(Patient.class).withId(id).execute();
		assertEquals(methodName, pt2.getName().get(0).getFamily());
	}

	@Test
	public void testWebsocketSubscription() throws Exception {
		/*
		 * Create subscription
		 */
		Subscription subscription = new Subscription();
		subscription.setReason("Monitor new neonatal function (note, age will be determined by the monitor)");
		subscription.setStatus(Subscription.SubscriptionStatus.REQUESTED);
		subscription.setCriteria("Observation?status=final");

		Subscription.SubscriptionChannelComponent channel = new Subscription.SubscriptionChannelComponent();
		channel.setType(Subscription.SubscriptionChannelType.WEBSOCKET);
		channel.setPayload("application/json");
		subscription.setChannel(channel);

		MethodOutcome methodOutcome = ourClient.create().resource(subscription).execute();
		IIdType mySubscriptionId = methodOutcome.getId();

		// Wait for the subscription to be activated
		waitForSize(1, () -> ourClient.search().forResource(Subscription.class).where(Subscription.STATUS.exactly().code("active")).cacheControl(new CacheControlDirective().setNoCache(true)).returnBundle(Bundle.class).execute().getEntry().size());

		/*
		 * Attach websocket
		 */

		WebSocketClient myWebSocketClient = new WebSocketClient();
		SocketImplementation mySocketImplementation = new SocketImplementation(mySubscriptionId.getIdPart(), EncodingEnum.JSON);

		myWebSocketClient.start();
		URI echoUri = new URI("ws://localhost:" + ourPort + "/hapi-fhir-jpaserver/websocket");
		ClientUpgradeRequest request = new ClientUpgradeRequest();
		ourLog.info("Connecting to : {}", echoUri);
		Future<Session> connection = myWebSocketClient.connect(mySocketImplementation, echoUri, request);
		Session session = connection.get(2, TimeUnit.SECONDS);

		ourLog.info("Connected to WS: {}", session.isOpen());

		/*
		 * Create a matching resource
		 */
		Observation obs = new Observation();
		obs.setStatus(Observation.ObservationStatus.FINAL);
		ourClient.create().resource(obs).execute();

		// Give some time for the subscription to deliver
		Thread.sleep(2000);

		/*
		 * Ensure that we receive a ping on the websocket
		 */
		waitForSize(1, () -> mySocketImplementation.myPingCount);

		/*
		 * Clean up
		 */
		ourClient.delete().resourceById(mySubscriptionId).execute();
	}

	@AfterClass
	public static void afterClass() throws Exception {
		ourServer.stop();
	}

	@BeforeClass
	public static void beforeClass() throws Exception {
		String path = Paths.get("").toAbsolutePath().toString();

		ourLog.info("Project base path is: {}", path);

		if (ourPort == 0) {
			ourPort = RandomServerPortProvider.findFreePort();
		}
		ourServer = new Server(ourPort);

		WebAppContext webAppContext = new WebAppContext();
		webAppContext.setContextPath("/hapi-fhir-jpaserver");
		webAppContext.setDescriptor(path + "/src/main/webapp/WEB-INF/web.xml");
		webAppContext.setResourceBase(path + "/target/hapi-fhir-jpaserver-starter");
		webAppContext.setParentLoaderPriority(true);

		ourServer.setHandler(webAppContext);
		ourServer.start();

		ourCtx.getRestfulClientFactory().setServerValidationMode(ServerValidationModeEnum.NEVER);
		ourCtx.getRestfulClientFactory().setSocketTimeout(1200 * 1000);
		ourServerBase = "http://localhost:" + ourPort + "/hapi-fhir-jpaserver/fhir/";
		ourClient = ourCtx.newRestfulGenericClient(ourServerBase);
		ourClient.registerInterceptor(new LoggingInterceptor(true));
	}

	public static void main(String[] theArgs) throws Exception {
		ourPort = 8080;
		beforeClass();
	}
}
