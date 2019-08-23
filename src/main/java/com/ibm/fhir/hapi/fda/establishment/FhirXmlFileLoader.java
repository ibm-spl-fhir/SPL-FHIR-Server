package com.ibm.fhir.hapi.fda.establishment;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.hl7.fhir.r4.model.BaseResource;

import ca.uhn.fhir.context.FhirContext;
import ca.uhn.fhir.parser.IParser;
import ca.uhn.fhir.parser.StrictErrorHandler;

public class FhirXmlFileLoader {
	
	 @SuppressWarnings("unchecked")
	public static <T extends BaseResource> List<T> loadFromDirectory(String rootDir) {
	        IParser xmlParser = FhirContext.forR4().newXmlParser();
	        xmlParser.setParserErrorHandler(new StrictErrorHandler());
	        List<T> definitions = new ArrayList<>();
	        File[] profiles =
	            new File(FhirXmlFileLoader.class.getClassLoader().getResource(rootDir).getFile()).listFiles();

	        Arrays.asList(profiles).forEach(f -> {
	            try {
	                T sd = (T) xmlParser.parseResource(new FileReader(f));
	                definitions.add(sd);
	            } catch (FileNotFoundException e) {
	                throw new RuntimeException(e);
	            }
	        });

	        return definitions;
	    }

}
