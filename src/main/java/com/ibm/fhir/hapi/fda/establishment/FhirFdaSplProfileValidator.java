package com.ibm.fhir.hapi.fda.establishment;

import org.hl7.fhir.r4.hapi.ctx.DefaultProfileValidationSupport;
import org.hl7.fhir.r4.hapi.ctx.IValidationSupport;
import org.hl7.fhir.r4.hapi.validation.FhirInstanceValidator;
import org.hl7.fhir.r4.hapi.validation.ValidationSupportChain;

import ca.uhn.fhir.context.FhirContext;
import ca.uhn.fhir.validation.FhirValidator;

public class FhirFdaSplProfileValidator  {
	
	public static FhirValidator initFhirValidator(FhirContext fhirContext) {
        FhirValidator validator = fhirContext.newValidator();
      
        IValidationSupport valSupport = new EstablishmentOrganizationValidationSupport();
        ValidationSupportChain support = new ValidationSupportChain(new DefaultProfileValidationSupport(), valSupport);
        FhirInstanceValidator instanceValidator = new FhirInstanceValidator(support);

        validator.registerValidatorModule(instanceValidator);
        return validator;
    }

}
