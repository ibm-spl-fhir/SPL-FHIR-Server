package com.ibm.fhir.hapi.fda.establishment;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import org.hl7.fhir.r4.hapi.ctx.DefaultProfileValidationSupport;
import org.hl7.fhir.r4.hapi.ctx.IValidationSupport;
import org.hl7.fhir.r4.model.BaseResource;
import org.hl7.fhir.r4.model.CodeSystem;
import org.hl7.fhir.r4.model.StructureDefinition;
import org.hl7.fhir.r4.model.ValueSet;

import ca.uhn.fhir.context.FhirContext;

public class EstablishmentOrganizationValidationSupport extends DefaultProfileValidationSupport implements IValidationSupport {

	private static String profileDir = "profiles";

    private HashMap<String, StructureDefinition> definitionsMap = new HashMap<>();
    private HashMap<String, ValueSet> valueSet = new HashMap<>();
    private HashMap<String, CodeSystem> codeMap = new HashMap<>();
    private HashMap<String, BaseResource> resourceMap = new HashMap<>();
    
    private List<BaseResource> definitions = new ArrayList<>();
    
    //private HapiWorkerContext context;

    public EstablishmentOrganizationValidationSupport() {
    	
        definitions = FhirXmlFileLoader.loadFromDirectory(profileDir);
        
        //Process the profile to create a Hash Maps of StructureDefinition, ValueSet etc
        definitionsMap = new HashMap<>();
        for (int i = 0;i < definitions.size();i++) {
        	BaseResource nextResource = definitions.get(i);
        	
        	if (nextResource instanceof StructureDefinition) {
        		StructureDefinition def = (StructureDefinition)nextResource;
        		definitionsMap.put(def.getUrl(),def);
        		resourceMap.put(def.getUrl(),nextResource);
        	} else if (nextResource instanceof ValueSet) {
        		ValueSet nextSet = (ValueSet)nextResource;
        		valueSet.put(nextSet.getUrl(),nextSet);
        		resourceMap.put(nextSet.getUrl(),nextResource);
        	} else if (nextResource instanceof CodeSystem) {
        		CodeSystem nextCode = (CodeSystem)nextResource;
        		codeMap.put(nextCode.getUrl(),nextCode);
        		resourceMap.put(nextCode.getUrl(),nextResource);
        	}
        	
        }
        
    }

    @Override
    public List<StructureDefinition> fetchAllStructureDefinitions(FhirContext theContext) {
    	
    	//Parse through the Hash map (which will only have Structure Definition etc) to 
    	//return the List of Structure Definitions
    	List<StructureDefinition> myDefList = new ArrayList<>();
    	definitionsMap.forEach((k, v) -> {
            myDefList.add(v);
        });
    	
        return myDefList;
    }

    
    @Override
    public CodeSystem fetchCodeSystem(FhirContext theContext, String theUrl) {
    	
    	CodeSystem myCodeSystem = codeMap.get(theUrl);
    	
    	return myCodeSystem;
    }
    

    @Override
    public StructureDefinition fetchStructureDefinition(FhirContext theCtx, String theUrl) {
        
    	return definitionsMap.get(theUrl);
		
    }
    
    /*

    @Override
    public boolean isCodeSystemSupported(FhirContext theContext, String theSystem) {
    	
    	//TODO Implement the method
    	
    	System.out.println("theSystem " + theSystem);
    	
    	context = new HapiWorkerContext(theContext,this);
    	return context.supportsSystem(theSystem);
    	
    }

    
    @Override
    public CodeValidationResult validateCode(FhirContext theContext, String theCodeSystem, String theCode, String theDisplay) {
        
    	//TODO Implement the method
    	
    	System.out.println("theCodeSystem " + theCodeSystem);
    	
    	System.out.println("theCode " + theCode);
    	
    	System.out.println("theDisplay " + theDisplay);
    	
    	//context = new HapiWorkerContext(theContext,this);
    	//CodeSystem x = context.fetchCodeSystem(theCodeSystem);
    	
    	return null;
    	
    }
    

	@Override
	public List<org.hl7.fhir.instance.model.api.IBaseResource> fetchAllConformanceResources(FhirContext theContext) {
		
		//TODO Implement the method
		
		return null;
		
	}
	
	@Override
	public ValueSetExpansionOutcome expandValueSet(FhirContext theContext, ConceptSetComponent theInclude) {
		
		//TODO Implement the method
		
		return null;
	}
	*/

	@Override
	public ValueSet fetchValueSet(FhirContext theContext, String uri) {
		
		return valueSet.get(uri);
	}

	@SuppressWarnings("unchecked")
	@Override
	public <T extends org.hl7.fhir.instance.model.api.IBaseResource> T fetchResource(FhirContext theContext,
			Class<T> theClass, String theUri) {
		return (T) resourceMap.get(theUri);
		 
	}


	
}
