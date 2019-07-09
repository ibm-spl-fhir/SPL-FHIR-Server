package com.ibm.fhir.hapi.fda.establishment;

import java.util.List;

import org.hl7.fhir.r4.model.CodeableConcept;
import org.hl7.fhir.r4.model.Composition;
import org.hl7.fhir.r4.model.Composition.SectionComponent;
import org.hl7.fhir.r4.model.DateTimeType;
import org.hl7.fhir.r4.model.Extension;
import org.hl7.fhir.r4.model.HealthcareService;
import org.hl7.fhir.r4.model.Identifier;
import org.hl7.fhir.r4.model.Organization;
import org.hl7.fhir.r4.model.OrganizationAffiliation;
import org.hl7.fhir.r4.model.Reference;
import org.hl7.fhir.r4.model.StringType;
import org.springframework.beans.factory.annotation.Autowired;

import ca.uhn.fhir.jpa.dao.IFhirResourceDao;
import ca.uhn.fhir.rest.annotation.Operation;
import ca.uhn.fhir.rest.annotation.OperationParam;
import ca.uhn.fhir.rest.server.IResourceProvider;

public class EstablishmentResourceProvider implements IResourceProvider {
	
	private static final CodeableConcept USAGENT_CONCEPT = new CodeableConcept().setText("USAGENT");
	private static final CodeableConcept IMPORTER_CONCEPT = new CodeableConcept().setText("IMPORTER");
	
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

	@Operation(name="$register-establishment")
	public Organization registerEstablishmentOperation(
		@OperationParam(name="ID", min=1, max=1) Identifier operationId,
		@OperationParam(name="setID", min=1, max=1) Identifier operationSetId,
		@OperationParam(name="versionNumber", min=1, max=1) StringType operationVersion,
		@OperationParam(name="date", min=1, max=1) DateTimeType operationDate,
		@OperationParam(name="registrant", min=1, max=1) Organization registrant,
		@OperationParam(name="establishment", min=1, max=1) Organization establishment,
		@OperationParam(name="operations", min=0, max=OperationParam.MAX_UNLIMITED) List<HealthcareService> operations,
		@OperationParam(name="usAgent", min=0, max=1) Organization usAgent,
		@OperationParam(name="importer", min=0, max=1) Organization importer) {
		
		//Create a composition that has the operation information
		//In real-world code, this would probably be a custom resource or a custom object
		Composition operationComposition = new Composition();
		operationComposition.setDateElement(operationDate);
		operationComposition.setIdentifier(operationSetId);
		Extension compIdentityExtension = new Extension();
		compIdentityExtension.addExtension(new Extension("url for id goes here", operationId));
		compIdentityExtension.addExtension(new Extension("url for id goes here", operationVersion));
		operationComposition.addExtension(compIdentityExtension);
		
		
		//Set the author of the composition to be the registrant
		operationComposition.addAuthor().setReference("#registrant");
		registrant.setId("#registrant");
		operationComposition.addContained(registrant);
		
		//Create a section in this composition that points to the establishment being registered.
		SectionComponent establishmentSection = operationComposition.addSection();
		establishmentSection.setTitle("Registered Establishment");

		// Figure out how to save all of these objects to the database
		getOrganizationDao().create(establishment);
		Reference establishmentRef = new Reference(establishment);
		
		establishmentSection.addEntry(establishmentRef);
		getCompositionDao().create(operationComposition);

		//Link the establishment to its operations
		for (HealthcareService operation: operations) {
			operation.setProvidedBy(establishmentRef);
			getServiceDao().create(operation);
		}
		
		//Link the establishment to its optional usAgent
		if (usAgent != null) {
			getOrganizationDao().create(usAgent);

			OrganizationAffiliation usAgentAffiliation = new OrganizationAffiliation();
			usAgentAffiliation.setOrganization(establishmentRef);
			usAgentAffiliation.setParticipatingOrganization(new Reference(usAgent));
			usAgentAffiliation.addCode(USAGENT_CONCEPT);
			
			getAffiliationDao().create(usAgentAffiliation);
			
		}
		
		//Link the establishment to its optional importer
		if (usAgent != null) {
			getOrganizationDao().create(importer);

			OrganizationAffiliation importerAffiliation = new OrganizationAffiliation();
			importerAffiliation.setOrganization(establishmentRef);
			importerAffiliation.setParticipatingOrganization(new Reference(importer));
			importerAffiliation.addCode(IMPORTER_CONCEPT);

			getAffiliationDao().create(importerAffiliation);
		}		
		
		return establishment;
		
	}
}
