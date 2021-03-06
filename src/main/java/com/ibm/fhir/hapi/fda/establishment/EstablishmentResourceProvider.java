package com.ibm.fhir.hapi.fda.establishment;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.hl7.fhir.instance.model.api.IBaseResource;
import org.hl7.fhir.instance.model.api.IIdType;
import org.hl7.fhir.r4.model.Bundle;
import org.hl7.fhir.r4.model.Bundle.BundleEntryComponent;
import org.hl7.fhir.r4.model.Bundle.BundleType;
import org.hl7.fhir.r4.model.CodeableConcept;
import org.hl7.fhir.r4.model.Coding;
import org.hl7.fhir.r4.model.Composition;
import org.hl7.fhir.r4.model.Composition.SectionComponent;
import org.hl7.fhir.r4.model.DateTimeType;
import org.hl7.fhir.r4.model.Extension;
import org.hl7.fhir.r4.model.HealthcareService;
import org.hl7.fhir.r4.model.Identifier;
import org.hl7.fhir.r4.model.Meta;
import org.hl7.fhir.r4.model.OperationOutcome;
import org.hl7.fhir.r4.model.Organization;
import org.hl7.fhir.r4.model.OrganizationAffiliation;
import org.hl7.fhir.r4.model.Reference;
import org.hl7.fhir.r4.model.StringType;
import org.springframework.beans.factory.annotation.Autowired;

import ca.uhn.fhir.context.FhirContext;
import ca.uhn.fhir.jpa.dao.IFhirResourceDao;
import ca.uhn.fhir.jpa.searchparam.SearchParameterMap;
import ca.uhn.fhir.jpa.starter.HapiProperties;
import ca.uhn.fhir.model.api.IQueryParameterType;
import ca.uhn.fhir.model.primitive.IdDt;
import ca.uhn.fhir.parser.DataFormatException;
import ca.uhn.fhir.parser.StrictErrorHandler;
import ca.uhn.fhir.rest.annotation.Operation;
import ca.uhn.fhir.rest.annotation.OperationParam;
import ca.uhn.fhir.rest.annotation.RequiredParam;
import ca.uhn.fhir.rest.annotation.ResourceParam;
import ca.uhn.fhir.rest.api.MethodOutcome;
import ca.uhn.fhir.rest.api.server.IBundleProvider;
import ca.uhn.fhir.rest.client.api.IGenericClient;
import ca.uhn.fhir.rest.param.ReferenceParam;
import ca.uhn.fhir.rest.param.TokenParam;
import ca.uhn.fhir.rest.server.IResourceProvider;
import ca.uhn.fhir.rest.server.exceptions.InternalErrorException;
import ca.uhn.fhir.rest.server.exceptions.InvalidRequestException;
import ca.uhn.fhir.validation.FhirValidator;
import ca.uhn.fhir.validation.IValidatorModule;
import ca.uhn.fhir.validation.SchemaBaseValidator;
import ca.uhn.fhir.validation.SingleValidationMessage;
import ca.uhn.fhir.validation.ValidationResult;
import ca.uhn.fhir.validation.schematron.SchematronBaseValidator;

public class EstablishmentResourceProvider implements IResourceProvider {

	private static final CodeableConcept USAGENT_CONCEPT = new CodeableConcept().setText("USAGENT");
	private static final CodeableConcept IMPORTER_CONCEPT = new CodeableConcept().setText("IMPORTER");
	private static final String DOCID_URL = "DOCID_URL";
	private static final String VERSION_NUMBER_URL = "VERSION_NUMBER_URL";

	@Autowired
	private IFhirResourceDao<Composition> compositionDao;
	@Autowired
	private IFhirResourceDao<Organization> organizationDao;
	@Autowired
	private IFhirResourceDao<HealthcareService> serviceDao;
	@Autowired
	private IFhirResourceDao<OrganizationAffiliation> affiliationDao;

	public IFhirResourceDao<Composition> getCompositionDao() {
		return compositionDao;
	}

	public IFhirResourceDao<Organization> getOrganizationDao() {
		return organizationDao;
	}

	public IFhirResourceDao<OrganizationAffiliation> getAffiliationDao() {
		return affiliationDao;
	}

	public IFhirResourceDao<HealthcareService> getServiceDao() {
		return serviceDao;
	}



	@Override
	public Class<Organization> getResourceType() {
		return Organization.class;
	}

	@SuppressWarnings("unused")
	@Operation(name="$register-establishment")
	public Organization registerEstablishmentOperation(
		@OperationParam(name="ID", min=1, max=1) Identifier operationId,
		@OperationParam(name="setID", min=1, max=1) Identifier operationSetId,
		@OperationParam(name="versionNumber", min=1, max=1) StringType operationVersion,
		@OperationParam(name="date", min=1, max=1) DateTimeType operationDate,
		@OperationParam(name="registrant", min=1, max=1) Organization registrant,
		@OperationParam(name="establishment", min=1, max=1) Organization establishment,
		@OperationParam(name="operations", min=0, max=OperationParam.MAX_UNLIMITED) List<HealthcareService> operations,
		@OperationParam(name="usAgent", min=0, max=OperationParam.MAX_UNLIMITED) List<Organization> usAgents,
		@OperationParam(name="importer", min=0, max=OperationParam.MAX_UNLIMITED) List<Organization> importers) {

		//Create a composition that has the operation information
		//In real-world code, this would probably be a custom resource or a custom object
		Composition operationComposition = new Composition();
		operationComposition.setDateElement(operationDate);
		operationComposition.setIdentifier(operationSetId);
		Extension compIdentityExtension = new Extension();
		compIdentityExtension.addExtension(new Extension(DOCID_URL, operationId));
		compIdentityExtension.addExtension(new Extension(VERSION_NUMBER_URL, operationVersion));
		operationComposition.addExtension(compIdentityExtension);
		operationComposition.setTitle("Establishment Registration");
		
		CodeableConcept compType = new CodeableConcept();
		Coding compTypeCoding = new Coding();
		compTypeCoding.setCode("51725-0");
		compTypeCoding.setSystem("http://loinc.org");
		compTypeCoding.setDisplay("ESTABLISHMENT REGISTRATION");
		compType.addCoding(compTypeCoding);
		operationComposition.setType(compType);


		//Set the author of the composition to be the registrant
		operationComposition.addAuthor().setReference("#registrant");
		registrant.setId("#registrant");
		operationComposition.addContained(registrant);
		
		//Validate the "Establishment" Organization resource
		//MethodOutcome out0 = validateOrganizationOperation(registrant);

		//Create a section in this composition that points to the establishment being registered.
		SectionComponent establishmentSection = operationComposition.addSection();
		establishmentSection.setTitle("Registered Establishment");

		//Validate the "Establishment" Organization resource
		MethodOutcome out1 = validateOrganizationOperation(establishment);
		
		// Figure out how to save all of these objects to the database
		
		getOrganizationDao().create(establishment);
		Reference establishmentRef = new Reference(establishment);

		establishmentSection.addEntry(establishmentRef);
		getCompositionDao().create(operationComposition);

		//Link the establishment to its operations
		for (HealthcareService operation: operations) {
			operation.setProvidedBy(establishmentRef);
			
			//Validate the HealthcareService resource
			MethodOutcome out2 = validateHealthcareServiceOperation(operation);
			
			getServiceDao().create(operation);
		}

		//Link the establishment to its optional usAgent. Handle multiple usAgent scenarios
		if (usAgents != null) {
			for (Organization usAgent: usAgents) {

			//Validate the "US Agent" Organization resource
			MethodOutcome out3 = validateOrganizationOperation(usAgent);
			getOrganizationDao().create(usAgent);

			OrganizationAffiliation usAgentAffiliation = new OrganizationAffiliation();
			usAgentAffiliation.setOrganization(establishmentRef);
			usAgentAffiliation.setParticipatingOrganization(new Reference(usAgent));
			usAgentAffiliation.addCode(USAGENT_CONCEPT);
			
			//Validate the Organization Affiliation resource
			MethodOutcome out4 = validateOrgAffiliationOperation(usAgentAffiliation);

			getAffiliationDao().create(usAgentAffiliation);
			}
		}

		//Link the establishment to its optional importer. Handle multiple Importer scenario
		if (importers != null) {
			for (Organization importer: importers) {
			//Validate the "Importer" Organization resource
			MethodOutcome out5 = validateOrganizationOperation(importer);
			getOrganizationDao().create(importer);

			OrganizationAffiliation importerAffiliation = new OrganizationAffiliation();
			importerAffiliation.setOrganization(establishmentRef);
			importerAffiliation.setParticipatingOrganization(new Reference(importer));
			importerAffiliation.addCode(IMPORTER_CONCEPT);
			
			//Validate the Organization Affiliation resource
			MethodOutcome out6 = validateOrgAffiliationOperation(importerAffiliation);

			getAffiliationDao().create(importerAffiliation);
			}
		}

		return establishment;

	}

	@Operation(name="$retrieve-establishment-old",idempotent=true)
	//Sample request: http://fhir.example.com/Organization/$retrieve-establishment
	public Bundle retrieveEstablishmentOperationOld(
			@RequiredParam(name=Organization.SP_IDENTIFIER) TokenParam establishmentID) {
			//@OperationParam(name="ID", min=1, max=1) Identifier establishmentId) {

		String identifierSystem = establishmentID.getSystem();
		String identifier = establishmentID.getValue();

		//Start querying various resources to retrieve them using the input Establishment "identifier"
		//and adding them to the response Bundle

		//Create the Bundle to store the Organization resources
		Bundle aggrBundle = new Bundle();
		int intSizeOrgBundle = 0;
		String strEstablishmentId = "";
		
		//Retrieve all the Organization resources using the input "identifier".
		//This includes the mandatory "Establishment", optional "US Agent" and
		//"Importer" Organization resources

		FhirContext fhirContext = FhirContext.forR4();
	    IGenericClient fhirClient = fhirContext.newRestfulGenericClient(HapiProperties.getServerAddress());

	    aggrBundle = fhirClient.search()
		         .forResource(Organization.class)
		         .where(Organization.IDENTIFIER.exactly().systemAndIdentifier(identifierSystem, identifier))
		         .returnBundle(Bundle.class).execute();
		intSizeOrgBundle = aggrBundle.getTotal();
		if (intSizeOrgBundle == 0) {
			
			return aggrBundle;
			
		} else if (intSizeOrgBundle > 1) {
			
			return aggrBundle;
		}

		//Parse through the Establishment organization to gets it ID. This will be used to retrieve other FHIR resources

		for (BundleEntryComponent entry : aggrBundle.getEntry() ) {
			//Property p = entry.getResource().getChildByName("name");
			//String s = entry.getResource().getChildByName("name").getValues().get(0).toString();
			//String i = entry.getResource().getIdElement().getIdPart();
			 if (entry.getResource().getChildByName("name").getValues().get(0).toString().equalsIgnoreCase("Establishment Organization")) {
				 strEstablishmentId = entry.getResource().getIdElement().getIdPart();
				 break;
			 }
		}

		//Retrieve the mandatory Registrant resource. This is stored in Composition resource
		
		Bundle compositionBundle = new Bundle();
		compositionBundle = fhirClient.search()
		 .forResource(Composition.class)
		 .where(Composition.ENTRY.hasId(strEstablishmentId))
		 .returnBundle(Bundle.class).execute();

		//Append the contents of the above Bundle to the Aggregate Bundle
		for (BundleEntryComponent entry : compositionBundle.getEntry() ) {
			if (!entry.isEmpty()) {
				aggrBundle.addEntry(entry);
			}
		}

		//Retrieve the mandatory HealthcareService resource
		Bundle healthcareSvcBundle = new Bundle();
		healthcareSvcBundle = fhirClient.search()
		 .forResource(HealthcareService.class)
		 .where(HealthcareService.ORGANIZATION.hasId(strEstablishmentId))
		 .returnBundle(Bundle.class).execute();

		//Append the contents of the above Bundle to the Aggregate Bundle
		for (BundleEntryComponent entry : healthcareSvcBundle.getEntry() ) {
			if (!entry.isEmpty()) {
				aggrBundle.addEntry(entry);
				aggrBundle.setTotal(aggrBundle.getTotal() + 1);
			}
		}

		//Using the Organization Affiliation, Retrieve the optional "US Agent", "Importer" resource using the "id" associated
		//with the retrieved Establishment Organization
		Bundle orgAffiliationBundle = new Bundle();
		orgAffiliationBundle = fhirClient.search()
		 .forResource(OrganizationAffiliation.class)
		 .where(OrganizationAffiliation.PRIMARY_ORGANIZATION.hasId(strEstablishmentId))
		 .returnBundle(Bundle.class).execute();

		//Append the contents of the above Bundle to the Aggregate Bundle
		for (BundleEntryComponent entry : orgAffiliationBundle.getEntry() ) {
			if (!entry.isEmpty()) {
				aggrBundle.addEntry(entry);
				aggrBundle.setTotal(aggrBundle.getTotal() + 1);
			}
		}

	    return aggrBundle;
    }
	
	@Operation(name="$retrieve-establishment",idempotent=true)
	//Sample request: http://fhir.example.com/Organization/$retrieve-establishment
	public Bundle retrieveEstablishmentOperation(
			@RequiredParam(name=Organization.SP_IDENTIFIER) TokenParam establishmentID) {
			

		String identifierSystem = establishmentID.getSystem();
		String identifier = establishmentID.getValue();

		//Create the Aggregate response Bundle
		Bundle aggrBundle = new Bundle();
		aggrBundle.setType(BundleType.SEARCHSET);
		aggrBundle.setId(new IdDt(java.util.UUID.randomUUID().toString()));
		int intSizeAggrBundle = 0;
		String strEstablishmentId = "";
		
		//Create the Bundle Entry List which will be added to the Aggregate Bundle
		ArrayList<BundleEntryComponent> entryList = new ArrayList<BundleEntryComponent>();
		
		String serverAddress = HapiProperties.getServerAddress();
		
		//Start querying various resources to retrieve them using the input Establishment "identifier"
		//and adding them to the response Bundle

		SearchParameterMap orgSearchMap = new SearchParameterMap();
		IQueryParameterType param1 = new TokenParam(identifierSystem,identifier);
		orgSearchMap.add("identifier",param1);
		IBundleProvider x1 = getOrganizationDao().search(orgSearchMap) ;
		
		//If the search retrieves no response OR receives more than 1 response then return 
		//an Error
		
		if (x1.size() == 0) {
			//Return Exception
			throw new InternalErrorException("No Establishment Organization found for the input Identifier");
			//return aggrBundle;
			
		} else if (x1.size() > 1) {
			//Return Exception
			throw new InternalErrorException("More than one Establishment Organization found for the input Identifier");
			//return aggrBundle;
		}
		
		List<IBaseResource> y1 = x1.getResources(0, x1.size());
		
		for (IBaseResource entry : y1) {
			 
			Organization o = (Organization)entry;
			//if (o.getName().equalsIgnoreCase("Establishment Organization")) {
				 //Append the retrieved resource to the Aggr response Bundle
				 intSizeAggrBundle = intSizeAggrBundle + 1;
				 strEstablishmentId = entry.getIdElement().getIdPart();
				 BundleEntryComponent myBundleEntryComponent = new BundleEntryComponent();
				 myBundleEntryComponent.setResource(o);
				 myBundleEntryComponent.setFullUrl(serverAddress + "Organization" + "/" + strEstablishmentId);
				  
				 entryList.add(myBundleEntryComponent);
				  
				 break;
			//}
		}

		//Retrieve the mandatory Registrant resource. This is stored in Composition resource
		
		SearchParameterMap compSearchMap = new SearchParameterMap();
		IQueryParameterType param2 = new ReferenceParam(strEstablishmentId);
		compSearchMap.add("entry",param2);
		IBundleProvider x2 = getCompositionDao().search(compSearchMap) ;
		List<IBaseResource> y2 = x2.getResources(0, x2.size());
		
		for (IBaseResource entry : y2) {
			 
			Composition o = (Composition)entry;
			if (!entry.isEmpty()) {
				 //Append the retrieved resource to the Aggr response Bundle
				 intSizeAggrBundle = intSizeAggrBundle + 1;				 
				 BundleEntryComponent myBundleEntryComponent = new BundleEntryComponent();
				 myBundleEntryComponent.setResource(o);
				 myBundleEntryComponent.setFullUrl(serverAddress + "Composition" + "/" + entry.getIdElement().getIdPart());
				  
				 entryList.add(myBundleEntryComponent);
				 
			}
		}

		//Retrieve the mandatory HealthcareService resource
		
		SearchParameterMap healthCareSvcSearchMap = new SearchParameterMap();
		IQueryParameterType param3 = new ReferenceParam(strEstablishmentId);
		healthCareSvcSearchMap.add("organization",param3);
		IBundleProvider x3 = getServiceDao().search(healthCareSvcSearchMap) ;
		List<IBaseResource> y3 = x3.getResources(0, x3.size());
		
		for (IBaseResource entry : y3) {
			 
			HealthcareService o = (HealthcareService)entry;
			if (!entry.isEmpty()) {
				 //Append the retrieved resource to the Aggr response Bundle
				 intSizeAggrBundle = intSizeAggrBundle + 1;		
				 BundleEntryComponent myBundleEntryComponent = new BundleEntryComponent();
				 myBundleEntryComponent.setResource(o);
				 myBundleEntryComponent.setFullUrl(serverAddress + "HealthcareService" + "/" + entry.getIdElement().getIdPart());
				
				 entryList.add(myBundleEntryComponent);
				 
			}
		}

		//Using the Organization Affiliation, Retrieve the optional "US Agent", "Importer" resource using the "id" associated
		//with the retrieved Establishment Organization
		
		ArrayList<IIdType> participatingOrgIDs = new ArrayList<IIdType>();
		
		SearchParameterMap orgAffiliationSearchMap = new SearchParameterMap();
		IQueryParameterType param4 = new ReferenceParam(strEstablishmentId);
		orgAffiliationSearchMap.add("primary-organization",param4);
		IBundleProvider x4 = getAffiliationDao().search(orgAffiliationSearchMap) ;
		List<IBaseResource> y4 = x4.getResources(0, x4.size());
		
		for (IBaseResource entry : y4) {
			 
			OrganizationAffiliation o = (OrganizationAffiliation)entry;
			if (!entry.isEmpty()) {
				 //Append the retrieved resource to the Aggr response Bundle
				 intSizeAggrBundle = intSizeAggrBundle + 1;		
				 BundleEntryComponent myBundleEntryComponent = new BundleEntryComponent();
				 myBundleEntryComponent.setResource(o);
				 myBundleEntryComponent.setFullUrl(serverAddress + "OrganizationAffiliation" + "/" + entry.getIdElement().getIdPart());
				
				 entryList.add(myBundleEntryComponent);
				
				
				//Also extract the ID of the participating organization for the purpose of retrieving it
				 IIdType zz = o.getParticipatingOrganization().getReferenceElement();
				 
				 participatingOrgIDs.add(zz);
			}
		}
		
		//Now retrieve the Participating Organization resources using the above extracted IDs
		
		for (IIdType entry : participatingOrgIDs) {

			Organization o = getOrganizationDao().read(entry);
			if (!o.isEmpty()) {
				 //Append the retrieved resource to the Aggr response Bundle
				 intSizeAggrBundle = intSizeAggrBundle + 1;		
				 BundleEntryComponent myBundleEntryComponent = new BundleEntryComponent();
				 myBundleEntryComponent.setResource(o);
				 myBundleEntryComponent.setFullUrl(serverAddress + "Organization" + "/" + entry);
				 
				 entryList.add(myBundleEntryComponent);
				 
				
			}
		}
	
		//Add the Resource Entry list to the Bundle
		aggrBundle.setEntry(entryList);
		aggrBundle.setTotal(intSizeAggrBundle);
		
		//Set the Meta Tags in Response Bundle
		Meta aggrMeta = new Meta();
		aggrMeta.setLastUpdated(new Date());
		aggrBundle.setMeta(aggrMeta);
		
		//Being prototype work, setting of the Response Tag in the Response Bundle is not required
		
	    return aggrBundle;
    }
	
	@Operation(name="$validate-organization")
	public MethodOutcome validateOrganizationOperation (
			@ResourceParam Organization myOrganization 
            
			){
		
		//if (myOrganization.getIdentifierFirstRep().isEmpty()) {
		//	throw new UnprocessableEntityException("No identifier supplied");
		//}
		
		//Set the custom profile based on the resource
		
		Meta m = myOrganization.getMeta();
		if (myOrganization.getName() != null) {
			if (myOrganization.getName().equalsIgnoreCase("Establishment Organization")) {		
				m.addProfile("http://fhir.fda.gov/spl-on-fhir/StructureDefinition/establishment-profile");
				myOrganization.setMeta(m);
			} else if (myOrganization.getName().equalsIgnoreCase("Registrant Organization")) {
				m.addProfile("http://fhir.fda.gov/spl-on-fhir/StructureDefinition/registrant-profile");
				myOrganization.setMeta(m);
			}
			/*
			else if (myOrganization.getName().equalsIgnoreCase("Establishment US Agent")) {
				m.addProfile("http://fhir.fda.gov/spl-on-fhir/StructureDefinition/establishment-profile");
				myOrganization.setMeta(m);
			} 
			else if (myOrganization.getName().equalsIgnoreCase("Establishment Importer")) {
				m.addProfile("http://fhir.fda.gov/spl-on-fhir/StructureDefinition/establishment-profile");
				myOrganization.setMeta(m);
			}
			*/
		}
		
		MethodOutcome mo = processCustomValidation(myOrganization);
		
		return mo;
				
	}
		
	
	
	@Operation(name="$validate-org-affiliation")
	public MethodOutcome validateOrgAffiliationOperation (
			@ResourceParam OrganizationAffiliation myOrgAffiliation
			){
		
		//if (myOrganization.getIdentifierFirstRep().isEmpty()) {
		//	throw new UnprocessableEntityException("No identifier supplied");
		//}
		
		//Set the custom profile based on the resource
		
		Meta m = myOrgAffiliation.getMeta();
		m.addProfile("http://fhir.fda.gov/spl-on-fhir/StructureDefinition/organizationaffiliation-profile");
		myOrgAffiliation.setMeta(m);		
		
		MethodOutcome mo = processCustomValidation(myOrgAffiliation);
		
		return mo;
				
	}
	
	@Operation(name="$validate-healthcare-service")
	public MethodOutcome validateHealthcareServiceOperation (
			@ResourceParam HealthcareService myService
			){
		
		//if (myOrganization.getIdentifierFirstRep().isEmpty()) {
		//	throw new UnprocessableEntityException("No identifier supplied");
		//}
		
		//Set the custom profile based on the resource
		
		Meta m = myService.getMeta();
		m.addProfile("http://fhir.fda.gov/spl-on-fhir/StructureDefinition/businessoperation-profile");
		myService.setMeta(m);		
		
		MethodOutcome mo = processCustomValidation(myService);
		
		return mo;
				
	}
	
	private MethodOutcome processCustomValidation(IBaseResource theResource) {
		
		
		MethodOutcome myOutcome = new MethodOutcome();
		
		FhirContext ctx = FhirContext.forR4();
		 
		// Ask the context for a validator
		//FhirValidator validator = ctx.newValidator();
		
		//Instantiate the Custom validator that will ALSO use the custom profile besides the Default one
		FhirValidator validator = FhirFdaSplProfileValidator.initFhirValidator(ctx);
		
		//Perform Strict Parser validation (like Data format or repeating attr value checks)
		try {
			ctx.setParserErrorHandler(new StrictErrorHandler());
		}
		catch (DataFormatException e) {
			 
			throw new InvalidRequestException("Following Data Format Error detected with the Organization Affiliation resource : " + e.getMessage());
		}
		 
		// Create Validator modules and register them 
		IValidatorModule module1 = new SchemaBaseValidator(ctx);
		validator.registerValidatorModule(module1);
		IValidatorModule module2 = new SchematronBaseValidator(ctx);
		validator.registerValidatorModule(module2);
		
		// Pass a resource in to be validated. The resource can
		// be an IBaseResource instance, or can be a raw String
		// containing a serialized resource as text.
		
		ValidationResult result = validator.validateWithResult(theResource);
		 
		// The result object now contains the validation results
		for (SingleValidationMessage next : result.getMessages()) {
		   System.out.println(next.getLocationString() + " " + next.getMessage());
		}
		
		OperationOutcome oo = (OperationOutcome) result.toOperationOutcome();
		String results = ctx.newXmlParser().setPrettyPrint(true).encodeResourceToString(oo);
		System.out.println(results);
		myOutcome.setOperationOutcome(oo);
		
		if (!result.isSuccessful()) {
			throw new InvalidRequestException("Validation of input Resource failed with Error : " + results);
		}
		
		return myOutcome;
	}
}
