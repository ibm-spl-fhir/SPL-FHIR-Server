<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" 
           xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
             xmlns="http://hl7.org/fhir" xmlns:v3="urn:hl7-org:v3"
             xmlns:xs="http://www.w3.org/2001/XMLSchema">
	
	<xsl:output method="xml"/>
	<xsl:output indent="yes"/>
	<xsl:variable name="bundleProfile" select='"http://hl7.org/fhir/StructureDefinition/Bundle"'/>
	<xsl:variable name="orgProfile" select='"http://hl7.org/fhir/StructureDefinition/Organization"'/>
	<xsl:variable name="healthcareProfile" select='"http://hl7.org/fhir/StructureDefinition/HealthcareService"'/>
	<xsl:variable name="hl7FhirUrl" select='"http://hl7.org/fhir"'/>
	<xsl:variable name="hl7CodeSysUrl" select='"http://ncimeta.nci.nih.gov"'/>
	 
	<xsl:variable name="urn_3986" select='"urn:ietf:rfc:3986"'/>
	<xsl:variable name="fldVersionNumber" select='"versionNumber"'/>
	<xsl:variable name="fldSetID" select='"setID"'/>
	<xsl:variable name="fldDate" select='"date"'/>
	<xsl:variable name="fldRegistrant" select='"registrant"'/>

	<xsl:template name="init-params" match="/">
		
		<xsl:element name = "Parameters">
		
			<xsl:element name = "meta">
				 <xsl:element name="lastUpdated">				   
                    <xsl:attribute name="value">
                      <xsl:value-of select="format-dateTime(current-dateTime(),
				          '[Y0001]-[M01]-[D01]T[h01]:[m01]:[s].[f]Z')"/>
                    </xsl:attribute>				   
				 </xsl:element>
				 
				 <xsl:element name="profile" >
				    <xsl:attribute name="value">
				      <xsl:copy-of select="$bundleProfile" />
				    </xsl:attribute>				   
				 </xsl:element>
			</xsl:element>
			
			<xsl:element name="parameter">
				<xsl:element name="name">
				   <xsl:attribute name="value">
				     <xsl:value-of select="//v3:document/v3:id/name()" />
				   </xsl:attribute>					
				</xsl:element>				
				<xsl:element name="valueIdentifier">				
					<xsl:element name="system">
					   <xsl:attribute name="value">
					     <xsl:copy-of select="$urn_3986" />
					   </xsl:attribute>						 
					</xsl:element>					
					<xsl:element name="value">
					   <xsl:attribute name="value">
					     <xsl:value-of select="concat('urn:uuid:', v3:document/v3:id/@root)" />
					   </xsl:attribute>						
					</xsl:element>					
				</xsl:element>			
			</xsl:element>
		
		    <xsl:element name="parameter">
		    	<xsl:element name="name">
		    	   <xsl:attribute name="value">
		    	     <xsl:copy-of select="$fldVersionNumber"/>
		    	   </xsl:attribute>		    	   
		    	</xsl:element>
		    	<xsl:element name="valueString">
		    		<xsl:attribute name="value">
		    	     <xsl:value-of select="v3:document/v3:versionNumber/@value" />
		    	   </xsl:attribute>
		    	</xsl:element>		    
		    </xsl:element>
		    
		    <xsl:element name="parameter">
		    	<xsl:element name="name">
		    	   <xsl:attribute name="value">
		    	     <xsl:copy-of select="$fldSetID"/>
		    	   </xsl:attribute>		    	   
		    	</xsl:element>
		    	<xsl:element name="valueIdentifier">				
					<xsl:element name="system">
					   <xsl:attribute name="value">
					     <xsl:copy-of select="$urn_3986" />
					   </xsl:attribute>						 
					</xsl:element>					
					<xsl:element name="value">
					   <xsl:attribute name="value">
					     <xsl:value-of select="concat('urn:uuid:', v3:document/v3:setId/@root)" />
					   </xsl:attribute>						
					</xsl:element>					
				</xsl:element>	    
		    </xsl:element>
		    
		    <xsl:element name="parameter">
		    	<xsl:element name="name">
		    	   <xsl:attribute name="value">
		    	     <xsl:copy-of select="$fldDate"/>
		    	   </xsl:attribute>		    	   
		    	</xsl:element>
			    	<xsl:element name="valueDateTime">					 
					   <xsl:attribute name="value">
					     <xsl:variable name="in" select="v3:document/v3:effectiveTime/@value" />
					      <xsl:variable name="effDate" select="xs:date(concat(
					     								substring($in,1,4),'-',
            											substring($in,5,2),'-',
            											substring($in,7,2)))"/>
            			 <xsl:value-of select="$effDate"/>
					   </xsl:attribute>				 			
				</xsl:element>	     
		    </xsl:element>
		
			<!-- Start the formatting of the mandatory Registration Organization
			     There can only be 1 such organization -->
			
			<xsl:apply-templates select="/v3:document/v3:author/v3:assignedEntity/v3:representedOrganization/v3:assignedEntity/v3:assignedOrganization">
			
			</xsl:apply-templates>
				
			<!-- Start the formatting of the mandatory Establishment Organizations. 
			     There can be minimum of 1 and maximum of any number of such organizations -->
			
			<xsl:apply-templates select="/v3:document/v3:author/v3:assignedEntity/v3:representedOrganization/v3:assignedEntity/v3:assignedOrganization/v3:assignedEntity">
			
			</xsl:apply-templates>
				
			<!-- Start the formatting of the Optional Importer and US Agent Organizations. 
			     For every establishment organization, there can be maximum of 1 US Agent and any number of Importer organizations  -->
			
			<xsl:apply-templates select="/v3:document/v3:author/v3:assignedEntity/v3:representedOrganization/v3:assignedEntity/v3:assignedOrganization/v3:assignedEntity/v3:assignedOrganization/v3:assignedEntity">
			
			</xsl:apply-templates>
			
			<!-- Start the formatting of the Business Operations (Health care service). 
			     For every establishment organization, there will be minimum of 1 and maximum of any number of Business operations  -->
			
			<xsl:apply-templates select="/v3:document/v3:author/v3:assignedEntity/v3:representedOrganization/v3:assignedEntity/v3:assignedOrganization/v3:assignedEntity/v3:performance">
			
			</xsl:apply-templates>
		

		</xsl:element>		<!-- End of Parameters Tag -->
        
	</xsl:template> 	<!-- End of Template to extract the initial parameters in the output XML -->

	
	<!-- Start of Template to format the Registration Organization -->

	<xsl:template name="registrant-template" match="/v3:document/v3:author/v3:assignedEntity/v3:representedOrganization/v3:assignedEntity/v3:assignedOrganization">

			<xsl:element name="parameter">
				<xsl:element name="name">
		    		<xsl:attribute name="value">
		    	     	<xsl:copy-of select="$fldRegistrant"/>
		        	</xsl:attribute>		    	   
		    	</xsl:element>
		    
		    	<xsl:element name="resource">
		    		<xsl:element name="Organization" namespace="http://hl7.org/fhir">
		    			 	
		        		<!-- We don't need to set the ID attribute. It is set by the FHIR registration operation -->	 
		        	
		        		<xsl:element name = "meta">
				 			<xsl:element name="lastUpdated">				   
                    			<xsl:attribute name="value">
                      				<xsl:value-of select="format-dateTime(current-dateTime(),
				         			 '[Y0001]-[M01]-[D01]T[h01]:[m01]:[s].[f]Z')"/>
                    			</xsl:attribute>				   
				 			</xsl:element>
				 
				 			<xsl:element name="profile" >
				    			<xsl:attribute name="value">
				     			 	<xsl:copy-of select="$orgProfile" />
				    			</xsl:attribute>				   
				 			</xsl:element>

		    			</xsl:element>
		    			
		    			<xsl:element name="identifier">				
							<xsl:element name="system">
					   			<xsl:attribute name="value">
					   				<xsl:value-of select="concat('urn:oid:', ./v3:id/@root)" />	     			
					   			</xsl:attribute>						 
							</xsl:element>					
							<xsl:element name="value">
					   			<xsl:attribute name="value">
					     			<xsl:value-of select="./v3:id/@extension" />
					   			</xsl:attribute>						
							</xsl:element>					
						</xsl:element>	
						
						<xsl:element name="active">
					   		<xsl:attribute name="value">
					   			<xsl:value-of select="'true'" />  			
					   		</xsl:attribute>						 
						</xsl:element>		
						
						<xsl:element name="name">
					   		<xsl:attribute name="value">
					   			<xsl:value-of select="./v3:name"/>					   			 			
					   		</xsl:attribute>						 
						</xsl:element>	
						
						<xsl:element name="contact">
							<xsl:element name="name">
								<xsl:element name="use">
									<xsl:attribute name="value">
					   					<xsl:value-of select="'usual'" />  			
					   				</xsl:attribute>
								</xsl:element>
								
								<!-- Parse the name and extract Given and family names -->
								<xsl:variable name="fullName" select="normalize-space(./v3:contactParty/v3:contactPerson/v3:name)"></xsl:variable>
								<xsl:variable name="givenName" select="substring-before($fullName,' ')"></xsl:variable>
								<xsl:variable name="familyName" select="substring-after($fullName,' ')"></xsl:variable>
								<xsl:element name="family">
									<xsl:attribute name="value">							
					   					<xsl:value-of select="$familyName" />  			
					   				</xsl:attribute>
								</xsl:element>
								<xsl:element name="given">
									<xsl:attribute name="value">
					   					<xsl:value-of select="$givenName" />  			
					   				</xsl:attribute>
								</xsl:element>
								<xsl:element name="prefix">
									<xsl:attribute name="value">
					   					<xsl:value-of select="'prefix'" />  			
					   				</xsl:attribute>
								</xsl:element>
								<xsl:element name="text">
									<xsl:attribute name="value">
					   					<xsl:value-of select="./v3:contactParty/v3:contactPerson/v3:name" />  			
					   				</xsl:attribute>
								</xsl:element>
							
							</xsl:element>
							
							<!-- Parse the input XML to extract the Telephone and Email IDs -->
							<xsl:for-each select="./v3:contactParty/v3:telecom">
							
							    <xsl:variable name="contactVar" select="@value"></xsl:variable>							    
							   
							    <xsl:if test="starts-with($contactVar,'tel')">
							    	<!-- Extract the telephone number -->
							        <xsl:variable name="phoneNumber" select="substring-after($contactVar,':')"></xsl:variable>
							        <xsl:element name="telecom">
							        	<xsl:element name="system">
											<xsl:attribute name="value">
					   							<xsl:value-of select="'phone'" />					   							
					   						</xsl:attribute>
										</xsl:element>
										<xsl:element name="value">
											<xsl:attribute name="value">
					   							<xsl:value-of select="$phoneNumber" />					   							
					   						</xsl:attribute>
										</xsl:element>
										<xsl:element name="use">
											<xsl:attribute name="value">
					   							<xsl:value-of select="'work'" />		<!-- Why is this being defaulted to Work -->			   							
					   						</xsl:attribute>
										</xsl:element>							
									</xsl:element>							        
							    </xsl:if>
							    <xsl:if test="starts-with($contactVar,'mailto')">
							   <!-- Extract the Email -->
							        <xsl:variable name="emailId" select="substring-after($contactVar,':')"></xsl:variable>
							        <xsl:element name="telecom">
							        	<xsl:element name="system">
											<xsl:attribute name="value">
					   							<xsl:value-of select="'email'" />					   							
					   						</xsl:attribute>
										</xsl:element>
										<xsl:element name="value">
											<xsl:attribute name="value">
					   							<xsl:value-of select="$emailId" />					   							
					   						</xsl:attribute>
										</xsl:element>
										<xsl:element name="use">
											<xsl:attribute name="value">
					   							<xsl:value-of select="'work'" />		<!-- Why is this being defaulted to Work -->			   							
					   						</xsl:attribute>
										</xsl:element>							
									</xsl:element>	
								 </xsl:if>
							</xsl:for-each>
							
							<!-- Parse and extract the Address details. If country is USA use State otherwise skip it -->
							<xsl:variable name="stateVar" select="./v3:contactParty/v3:addr/v3:country"></xsl:variable>
							<xsl:element name="address">								
								<xsl:element name="text">								    
									<xsl:choose>
										<xsl:when test="starts-with($stateVar,'USA') or starts-with($stateVar,'CHE')">											 
											<xsl:attribute name="value">
												<xsl:value-of select="concat(./v3:contactParty/v3:addr/v3:streetAddressLine,', ',
																	./v3:contactParty/v3:addr/v3:city,', ',
																	./v3:contactParty/v3:addr/v3:state,', ',
																	./v3:contactParty/v3:addr/v3:postalCode,', ',
																	./v3:contactParty/v3:addr/v3:country )">
												</xsl:value-of>				   							
		   									</xsl:attribute>									 
										</xsl:when>										 
										<xsl:otherwise>
											<xsl:attribute name="value">
												<xsl:value-of select="concat(./v3:contactParty/v3:addr/v3:streetAddressLine,', ',
																	./v3:contactParty/v3:addr/v3:city,', ',
																	./v3:contactParty/v3:addr/v3:postalCode,', ',
																	./v3:contactParty/v3:addr/v3:country )">
												</xsl:value-of>				   							
		   									</xsl:attribute>										
										</xsl:otherwise>									
									</xsl:choose>							
								</xsl:element>
								<xsl:element name="line">
									<xsl:attribute name="value">
			   							<xsl:value-of select="./v3:contactParty/v3:addr/v3:streetAddressLine" />					   							
			   						</xsl:attribute>
								</xsl:element>
								<xsl:element name="city">
									<xsl:attribute name="value">
			   							<xsl:value-of select="./v3:contactParty/v3:addr/v3:city" />					   							
			   						</xsl:attribute>
								</xsl:element>
								<xsl:choose>
									<xsl:when test="starts-with($stateVar,'USA') or starts-with($stateVar,'CHE')">
										<xsl:element name="state">
											<xsl:attribute name="value">
			   									<xsl:value-of select="./v3:contactParty/v3:addr/v3:state" />		 
			   								</xsl:attribute>
										</xsl:element>
									</xsl:when>							
								</xsl:choose>								
								<xsl:element name="postalCode">
									<xsl:attribute name="value">
			   							<xsl:value-of select="./v3:contactParty/v3:addr/v3:postalCode" />		 
			   						</xsl:attribute>
								</xsl:element>
								<xsl:element name="country">
									<xsl:attribute name="value">
			   							<xsl:value-of select="./v3:contactParty/v3:addr/v3:country" />		 
			   						</xsl:attribute>
								</xsl:element>					
					        						
							</xsl:element>	<!-- end of address tag -->
					   								 
						</xsl:element>		<!-- end of contact tag -->
		    			
		    		</xsl:element> <!-- end of Organization tag -->
		    
		    	</xsl:element> <!-- end of resource tag -->
		    
		   </xsl:element> <!-- end of parameter tag -->

		</xsl:template>	<!-- end of registrant template -->
	

	<!-- Start of Template to format the Establishment Organization -->
	
	<xsl:template name="establishment-template" match="/v3:document/v3:author/v3:assignedEntity/v3:representedOrganization/v3:assignedEntity/v3:assignedOrganization/v3:assignedEntity">

		<xsl:for-each select="./v3:assignedOrganization">
		
			<xsl:element name="parameter">
				<xsl:element name="name">
		    		<xsl:attribute name="value">
		    	     	<xsl:copy-of select="'establishment'"/>
		        	</xsl:attribute>		    	   
		    	</xsl:element>
		    
		    	<xsl:element name="resource">
		    		<xsl:element name="Organization" namespace="http://hl7.org/fhir">
		    			  
		        		<!-- We don't need to set the ID attribute. It is set by the FHIR registration operation -->	  
		        	
		        		<xsl:element name = "meta">
				 			<xsl:element name="lastUpdated">				   
                    			<xsl:attribute name="value">
                      				<xsl:value-of select="format-dateTime(current-dateTime(),
				         			 '[Y0001]-[M01]-[D01]T[h01]:[m01]:[s].[f]Z')"/>
                    			</xsl:attribute>				   
				 			</xsl:element>
				 
				 			<xsl:element name="profile" >
				    			<xsl:attribute name="value">
				     			 	<xsl:copy-of select="$orgProfile" />
				    			</xsl:attribute>				   
				 			</xsl:element>

		    			</xsl:element>
		    			
						<!-- Parse and extract the identifiers -->
						
						<xsl:for-each select="./v3:id">
						
							<xsl:variable name="identifierVar" select="@extension"></xsl:variable>
							<xsl:if test="starts-with($identifierVar,'00000000')">
								<xsl:element name="identifier">				
									<xsl:element name="system">
							   			<xsl:attribute name="value">
							   				<xsl:value-of select="concat('urn:oid:', ./@root)" />	     			
							   			</xsl:attribute>						 
									</xsl:element>					
									<xsl:element name="value">
							   			<xsl:attribute name="value">
							     			<xsl:value-of select="./@extension" />
							   			</xsl:attribute>						
									</xsl:element>					
								</xsl:element>
							
							</xsl:if>
							
							<xsl:if test="starts-with($identifierVar,'90000000')">
							
								<xsl:element name="identifier">				
									<xsl:element name="system">
							   			<xsl:attribute name="value">
							   				<xsl:value-of select="concat('urn:oid:', ./@root)" />	     			
							   			</xsl:attribute>						 
									</xsl:element>					
									<xsl:element name="value">
							   			<xsl:attribute name="value">
							     			<xsl:value-of select="./@extension" />
							   			</xsl:attribute>						
									</xsl:element>					
								</xsl:element>
							
							</xsl:if>
						
						</xsl:for-each>
							
						<xsl:element name="active">
					   		<xsl:attribute name="value">
					   			<xsl:value-of select="'true'" />  			
					   		</xsl:attribute>						 
						</xsl:element>		
						
						<xsl:element name="name">
					   		<xsl:attribute name="value">
					   			<xsl:value-of select="./v3:name"/>			
					   		</xsl:attribute>						 
						</xsl:element>	
						
						<!-- Parse and extract Address of Establishment organization. If it is USA then consider state -->
						<xsl:variable name="stateVar" select="./v3:addr/v3:country"></xsl:variable>
						<xsl:element name="address">								
							<xsl:element name="text">								
								<xsl:choose>
									<xsl:when test="starts-with($stateVar,'USA') or starts-with($stateVar,'CHE')">											 
										<xsl:attribute name="value">
											<xsl:value-of select="concat(./v3:addr/v3:streetAddressLine,', ',
																./v3:addr/v3:city,', ',
																./v3:addr/v3:state,', ',
																./v3:addr/v3:postalCode,', ',
																./v3:addr/v3:country )">
											</xsl:value-of>				   							
	   									</xsl:attribute>									 
									</xsl:when>
									<xsl:otherwise>
										<xsl:attribute name="value">
											<xsl:value-of select="concat(./v3:addr/v3:streetAddressLine,', ',
																./v3:addr/v3:city,', ',
																./v3:addr/v3:postalCode,', ',
																./v3:addr/v3:country )">
											</xsl:value-of>				   							
	   									</xsl:attribute>										
									</xsl:otherwise>									
								</xsl:choose>	
							</xsl:element>
							<xsl:element name="line">
								<xsl:attribute name="value">
		   							<xsl:value-of select="./v3:addr/v3:streetAddressLine" />					   							
		   						</xsl:attribute>
							</xsl:element>
							<xsl:element name="city">
								<xsl:attribute name="value">
		   							<xsl:value-of select="./v3:addr/v3:city" />					   							
		   						</xsl:attribute>
							</xsl:element>
							<xsl:choose>
									<xsl:when test="starts-with($stateVar,'USA') or starts-with($stateVar,'CHE')">
										<xsl:element name="state">
											<xsl:attribute name="value">
			   									<xsl:value-of select="./v3:addr/v3:state" />		 
			   								</xsl:attribute>
										</xsl:element>
									</xsl:when>							
							</xsl:choose>		
							<xsl:element name="postalCode">
								<xsl:attribute name="value">
		   							<xsl:value-of select="./v3:addr/v3:postalCode" />		 
		   						</xsl:attribute>
							</xsl:element>
							<xsl:element name="country">
								<xsl:attribute name="value">
		   							<xsl:value-of select="./v3:addr/v3:country" />		 
		   						</xsl:attribute>
							</xsl:element>					
				        						
						</xsl:element>
						
						<!-- Parse and extract Contact details of Establishment organization -->
						
						<xsl:element name="contact">
							<xsl:element name="name">
								<xsl:element name="use">
									<xsl:attribute name="value">
					   					<xsl:value-of select="'usual'" />  			
					   				</xsl:attribute>
								</xsl:element>
		
								<!-- Parse the name and extract Given and family names -->
								<xsl:variable name="fullName" select="normalize-space(./v3:contactParty/v3:contactPerson/v3:name)"></xsl:variable>
								<xsl:variable name="givenName" select="substring-before($fullName,' ')"></xsl:variable>
								<xsl:variable name="familyName" select="substring-after($fullName,' ')"></xsl:variable>
								<xsl:element name="family">
									<xsl:attribute name="value">							
					   					<xsl:value-of select="$familyName" />  			
					   				</xsl:attribute>
								</xsl:element>
								<xsl:element name="given">
									<xsl:attribute name="value">
					   					<xsl:value-of select="$givenName" />  			
					   				</xsl:attribute>
								</xsl:element>
								<xsl:element name="prefix">
									<xsl:attribute name="value">
					   					<xsl:value-of select="'prefix'" />  			
					   				</xsl:attribute>
								</xsl:element>
								<xsl:element name="text">
									<xsl:attribute name="value">
					   					<xsl:value-of select="./v3:contactParty/v3:contactPerson/v3:name" />    			
					   				</xsl:attribute>
								</xsl:element>
							
							</xsl:element>
							
							<!-- Parse the input XML to extract the Telephone and Email IDs -->
							<xsl:for-each select="./v3:contactParty/v3:telecom">
							
							    <xsl:variable name="contactVar" select="@value"></xsl:variable>							    
							   
							    <xsl:if test="starts-with($contactVar,'tel')">
							    	<!-- Extract the telephone number -->
							        <xsl:variable name="phoneNumber" select="substring-after($contactVar,':')"></xsl:variable>
							        <xsl:element name="telecom">
							        	<xsl:element name="system">
											<xsl:attribute name="value">
					   							<xsl:value-of select="'phone'" />					   							
					   						</xsl:attribute>
										</xsl:element>
										<xsl:element name="value">
											<xsl:attribute name="value">
					   							<xsl:value-of select="$phoneNumber" />					   							
					   						</xsl:attribute>
										</xsl:element>
										<xsl:element name="use">
											<xsl:attribute name="value">
					   							<xsl:value-of select="'work'" />		<!-- Why is this being defaulted to Work -->			   							
					   						</xsl:attribute>
										</xsl:element>							
									</xsl:element>							        
							    </xsl:if>
							    <xsl:if test="starts-with($contactVar,'mailto')">
							   <!-- Extract the Email -->
							        <xsl:variable name="emailId" select="substring-after($contactVar,':')"></xsl:variable>
							        <xsl:element name="telecom">
							        	<xsl:element name="system">
											<xsl:attribute name="value">
					   							<xsl:value-of select="'email'" />					   							
					   						</xsl:attribute>
										</xsl:element>
										<xsl:element name="value">
											<xsl:attribute name="value">
					   							<xsl:value-of select="$emailId" />					   							
					   						</xsl:attribute>
										</xsl:element>
										<xsl:element name="use">
											<xsl:attribute name="value">
					   							<xsl:value-of select="'work'" />		<!-- Why is this being defaulted to Work -->			   							
					   						</xsl:attribute>
										</xsl:element>							
									</xsl:element>	
								 </xsl:if>
							</xsl:for-each>
							
							<!-- Parse and extract the Address details. if it is USA then consider state -->
							<xsl:variable name="stateVar" select="./v3:contactParty/v3:addr/v3:country"></xsl:variable>
							<xsl:element name="address">								
								<xsl:element name="text">									
									<xsl:choose>
										<xsl:when test="starts-with($stateVar,'USA') or starts-with($stateVar,'CHE')">											 
											<xsl:attribute name="value">
												<xsl:value-of select="concat(./v3:contactParty/v3:addr/v3:streetAddressLine,', ',
																	./v3:contactParty/v3:addr/v3:city,', ',
																	./v3:contactParty/v3:addr/v3:state,', ',
																	./v3:contactParty/v3:addr/v3:postalCode,', ',
																	./v3:contactParty/v3:addr/v3:country )">
												</xsl:value-of>				   							
		   									</xsl:attribute>									 
										</xsl:when>
										<xsl:otherwise>
											<xsl:attribute name="value">
												<xsl:value-of select="concat(./v3:contactParty/v3:addr/v3:streetAddressLine,', ',
																	./v3:contactParty/v3:addr/v3:city,', ',
																	./v3:contactParty/v3:addr/v3:postalCode,', ',
																	./v3:contactParty/v3:addr/v3:country )">
												</xsl:value-of>				   							
		   									</xsl:attribute>										
										</xsl:otherwise>									
									</xsl:choose>	
								</xsl:element>
								<xsl:element name="line">
									<xsl:attribute name="value">
			   							<xsl:value-of select="./v3:contactParty/v3:addr/v3:streetAddressLine" />					   							
			   						</xsl:attribute>
								</xsl:element>
								<xsl:element name="city">
									<xsl:attribute name="value">
			   							<xsl:value-of select="./v3:contactParty/v3:addr/v3:city" />					   							
			   						</xsl:attribute>
								</xsl:element>
								<xsl:choose>
									<xsl:when test="starts-with($stateVar,'USA') or starts-with($stateVar,'CHE')">
										<xsl:element name="state">
											<xsl:attribute name="value">
			   									<xsl:value-of select="./v3:contactParty/v3:addr/v3:state" />		 
			   								</xsl:attribute>
										</xsl:element>
									</xsl:when>						
								</xsl:choose>		
								<xsl:element name="postalCode">
									<xsl:attribute name="value">
			   							<xsl:value-of select="./v3:contactParty/v3:addr/v3:postalCode" />		 
			   						</xsl:attribute>
								</xsl:element>
								<xsl:element name="country">
									<xsl:attribute name="value">
			   							<xsl:value-of select="./v3:contactParty/v3:addr/v3:country" />		 
			   						</xsl:attribute>
								</xsl:element>					
					        						
							</xsl:element>	<!-- end of address tag -->
					   								 
						</xsl:element>		<!-- end of contact tag -->
		    			
		    		</xsl:element> <!-- end of Organization tag -->
		    
		    	</xsl:element> <!-- end of resource tag -->
		    
		   </xsl:element> <!-- end of parameter tag -->
		
		
		</xsl:for-each>

	</xsl:template>	<!-- end of establishment template -->
	
	
	<!-- Start of Template to format the US Agent / Importer Organizations -->
	
	<xsl:template name="usAgent-Importer-template" match="/v3:document/v3:author/v3:assignedEntity/v3:representedOrganization/v3:assignedEntity/v3:assignedOrganization/v3:assignedEntity/v3:assignedOrganization/v3:assignedEntity">

		<xsl:for-each select="./v3:performance/v3:actDefinition/v3:code">
		
			<xsl:variable name="orgType" select="@code"></xsl:variable>
		
			<xsl:choose>		<!-- check to see if it is an US Agent or Importer Organization -->
			
				<xsl:when test="starts-with($orgType,'C73330')">	<!-- this is US Agent -->
				
					<xsl:element name="parameter">
						<xsl:element name="name">
				    		<xsl:attribute name="value">
				    	     	<xsl:copy-of select="'usAgent'"/>
				        	</xsl:attribute>		    	   
				    	</xsl:element>
			    
				    	<xsl:element name="resource">
				    		<xsl:element name="Organization" namespace="http://hl7.org/fhir">
				    			 
				        		<!-- We don't need to set the ID attribute. It is set by the FHIR registration operation -->		 
				        	
				        		<xsl:element name = "meta">
						 			<xsl:element name="lastUpdated">				   
			                   			<xsl:attribute name="value">
			                     				<xsl:value-of select="format-dateTime(current-dateTime(),
						         			 '[Y0001]-[M01]-[D01]T[h01]:[m01]:[s].[f]Z')"/>
			                   			</xsl:attribute>				   
						 			</xsl:element>
						 
						 			<xsl:element name="profile" >
						    			<xsl:attribute name="value">
						     			 	<xsl:copy-of select="$orgProfile" />
						    			</xsl:attribute>				   
						 			</xsl:element>
			
				    			</xsl:element>
				    			
								<!-- Parse and extract the identifiers -->
								
								<xsl:element name="identifier">				
									<xsl:element name="system">
							   			<xsl:attribute name="value">
							   				<xsl:value-of select="concat('urn:oid:', ./../../../v3:assignedOrganization/v3:id/@root)" />	     			
							   			</xsl:attribute>						 
									</xsl:element>					
									<xsl:element name="value">
							   			<xsl:attribute name="value">
							     			<xsl:value-of select="./../../../v3:assignedOrganization/v3:id/@extension" />
							   			</xsl:attribute>						
									</xsl:element>					
								</xsl:element>
									
								<xsl:element name="active">
							   		<xsl:attribute name="value">
							   			<xsl:value-of select="'true'" />  			
							   		</xsl:attribute>						 
								</xsl:element>		
								
								<xsl:element name="name">
							   		<xsl:attribute name="value">
							   			<xsl:value-of select="./../../../v3:assignedOrganization/v3:name"/> 			
							   		</xsl:attribute>						 
								</xsl:element>	
								
								<!-- Parse the input XML to extract the Telephone and Email IDs -->
								<xsl:for-each select="./../../../v3:assignedOrganization/v3:telecom">
								
								    <xsl:variable name="contactVar" select="@value"></xsl:variable>							    
								   
								    <xsl:if test="starts-with($contactVar,'tel')">
								    	<!-- Extract the telephone number -->
								        <xsl:variable name="phoneNumber" select="substring-after($contactVar,':')"></xsl:variable>
								        <xsl:element name="telecom">
								        	<xsl:element name="system">
												<xsl:attribute name="value">
						   							<xsl:value-of select="'phone'" />					   							
						   						</xsl:attribute>
											</xsl:element>
											<xsl:element name="value">
												<xsl:attribute name="value">
						   							<xsl:value-of select="$phoneNumber" />					   							
						   						</xsl:attribute>
											</xsl:element>
											<xsl:element name="use">
												<xsl:attribute name="value">
						   							<xsl:value-of select="'work'" />		<!-- Why is this being defaulted to Work -->			   							
						   						</xsl:attribute>
											</xsl:element>							
										</xsl:element>							        
								    </xsl:if>
								    <xsl:if test="starts-with($contactVar,'mailto')">
								   <!-- Extract the Email -->
								        <xsl:variable name="emailId" select="substring-after($contactVar,':')"></xsl:variable>
								        <xsl:element name="telecom">
								        	<xsl:element name="system">
												<xsl:attribute name="value">
						   							<xsl:value-of select="'email'" />					   							
						   						</xsl:attribute>
											</xsl:element>
											<xsl:element name="value">
												<xsl:attribute name="value">
						   							<xsl:value-of select="$emailId" />					   							
						   						</xsl:attribute>
											</xsl:element>
											<xsl:element name="use">
												<xsl:attribute name="value">
						   							<xsl:value-of select="'work'" />		<!-- Why is this being defaulted to Work -->			   							
						   						</xsl:attribute>
											</xsl:element>							
										</xsl:element>	
									 </xsl:if>
								</xsl:for-each>
								
							</xsl:element>
				    	</xsl:element>
				    </xsl:element>
				
				</xsl:when>
			
			</xsl:choose>
			
			<xsl:choose>		
			
				<xsl:when test="starts-with($orgType,'C73599')">	<!-- this is Importer -->
				
					<xsl:element name="parameter">
						<xsl:element name="name">
				    		<xsl:attribute name="value">
				    	     	<xsl:copy-of select="'importer'"/>
				        	</xsl:attribute>		    	   
				    	</xsl:element>
			    
				    	<xsl:element name="resource">
				    		<xsl:element name="Organization" namespace="http://hl7.org/fhir">
				    			 
				        		<!-- We don't need to set the ID attribute. It is set by the FHIR registration operation -->		  
				        	
				        		<xsl:element name = "meta">
						 			<xsl:element name="lastUpdated">				   
			                   			<xsl:attribute name="value">
			                     				<xsl:value-of select="format-dateTime(current-dateTime(),
						         			 '[Y0001]-[M01]-[D01]T[h01]:[m01]:[s].[f]Z')"/>
			                   			</xsl:attribute>				   
						 			</xsl:element>
						 
						 			<xsl:element name="profile" >
						    			<xsl:attribute name="value">
						     			 	<xsl:copy-of select="$orgProfile" />
						    			</xsl:attribute>				   
						 			</xsl:element>
			
				    			</xsl:element>
				    			
								<!-- Parse and extract the identifiers -->
								
								<xsl:element name="identifier">				
									<xsl:element name="system">
							   			<xsl:attribute name="value">
							   				<xsl:value-of select="concat('urn:oid:', ./../../../v3:assignedOrganization/v3:id/@root)" />	     			
							   			</xsl:attribute>						 
									</xsl:element>					
									<xsl:element name="value">
							   			<xsl:attribute name="value">
							     			<xsl:value-of select="./../../../v3:assignedOrganization/v3:id/@extension" />
							   			</xsl:attribute>						
									</xsl:element>					
								</xsl:element>
									
								<xsl:element name="active">
							   		<xsl:attribute name="value">
							   			<xsl:value-of select="'true'" />  			
							   		</xsl:attribute>						 
								</xsl:element>		
								
								<xsl:element name="name">
							   		<xsl:attribute name="value">
							   			<xsl:value-of select="./../../../v3:assignedOrganization/v3:name"/>		
							   		</xsl:attribute>						 
								</xsl:element>	
								
								<!-- Parse the input XML to extract the Telephone and Email IDs -->
								<xsl:for-each select="./../../../v3:assignedOrganization/v3:telecom">
								
								    <xsl:variable name="contactVar" select="@value"></xsl:variable>							    
								   
								    <xsl:if test="starts-with($contactVar,'tel')">
								    	<!-- Extract the telephone number -->
								        <xsl:variable name="phoneNumber" select="substring-after($contactVar,':')"></xsl:variable>
								        <xsl:element name="telecom">
								        	<xsl:element name="system">
												<xsl:attribute name="value">
						   							<xsl:value-of select="'phone'" />					   							
						   						</xsl:attribute>
											</xsl:element>
											<xsl:element name="value">
												<xsl:attribute name="value">
						   							<xsl:value-of select="$phoneNumber" />					   							
						   						</xsl:attribute>
											</xsl:element>
											<xsl:element name="use">
												<xsl:attribute name="value">
						   							<xsl:value-of select="'work'" />		<!-- Why is this being defaulted to Work -->			   							
						   						</xsl:attribute>
											</xsl:element>							
										</xsl:element>							        
								    </xsl:if>
								    <xsl:if test="starts-with($contactVar,'mailto')">
								   <!-- Extract the Email -->
								        <xsl:variable name="emailId" select="substring-after($contactVar,':')"></xsl:variable>
								        <xsl:element name="telecom">
								        	<xsl:element name="system">
												<xsl:attribute name="value">
						   							<xsl:value-of select="'email'" />					   							
						   						</xsl:attribute>
											</xsl:element>
											<xsl:element name="value">
												<xsl:attribute name="value">
						   							<xsl:value-of select="$emailId" />					   							
						   						</xsl:attribute>
											</xsl:element>
											<xsl:element name="use">
												<xsl:attribute name="value">
						   							<xsl:value-of select="'work'" />		<!-- Why is this being defaulted to Work -->			   							
						   						</xsl:attribute>
											</xsl:element>							
										</xsl:element>	
									 </xsl:if>
								</xsl:for-each>
								
								
							</xsl:element>
				    	</xsl:element>
				    </xsl:element>
				
				</xsl:when>
			
			</xsl:choose>
		
		</xsl:for-each>

	</xsl:template>	<!-- end of US Agent template -->
	
	<!-- Start of Template to format the Business Operation -->
	
	<xsl:template name="business-operation-template" match="/v3:document/v3:author/v3:assignedEntity/v3:representedOrganization/v3:assignedEntity/v3:assignedOrganization/v3:assignedEntity/v3:performance">
		
		<xsl:for-each select="v3:actDefinition">		
		
			<xsl:element name="parameter">
					<xsl:element name="name">
			    		<xsl:attribute name="value">
			    	     	<xsl:copy-of select="'operations'"/>
			        	</xsl:attribute>		    	   
			    	</xsl:element>
		    
			    	<xsl:element name="resource">
			    		<xsl:element name="HealthcareService" namespace="http://hl7.org/fhir">
			    			 
			        		<!-- We don't need to set the ID attribute. It is set by the FHIR registration operation -->	  
			        	
			        		<xsl:element name = "meta">
					 			<xsl:element name="lastUpdated">				   
		                   			<xsl:attribute name="value">
		                     				<xsl:value-of select="format-dateTime(current-dateTime(),
					         			 '[Y0001]-[M01]-[D01]T[h01]:[m01]:[s].[f]Z')"/>
		                   			</xsl:attribute>				   
					 			</xsl:element>
					 
					 			<xsl:element name="profile" >
					    			<xsl:attribute name="value">
					     			 	<xsl:copy-of select="$healthcareProfile" />
					    			</xsl:attribute>				   
					 			</xsl:element>
		
			    			</xsl:element>
			    			
			    			<!-- We don't need to set the providedBy. It is set by the FHIR registration operation -->	
			    			
			    			<xsl:element name="type">
			    				<xsl:element name="coding">
			    					<xsl:element name="system">
			    						<xsl:attribute name="value">			    					
			    							<xsl:copy-of select="$hl7CodeSysUrl"/>			    					
			    						</xsl:attribute>			    						 	    					
			    					</xsl:element>
			    					<xsl:element name="code">
			    						<xsl:attribute name="value">			    					
			    							<xsl:value-of select="./v3:code/@code"></xsl:value-of>			    					
			    						</xsl:attribute>			    						 	    					
			    					</xsl:element>
			    					<xsl:element name="display">
			    						<xsl:attribute name="value">			    					
			    							<xsl:value-of select="./v3:code/@displayName"></xsl:value-of>			    					
			    						</xsl:attribute>			    						 	    					
			    					</xsl:element>	    				
			    				</xsl:element>			    			
			    			</xsl:element>
			    			
			    			<xsl:for-each select="./v3:subjectOf/v3:approval">
			    			
			    				<xsl:element name="specialty">
				    				<xsl:element name="coding">
				    					<xsl:element name="system">
				    						<xsl:attribute name="value">			
				    							<xsl:copy-of select="$hl7CodeSysUrl"/>				    							 		    					
				    						</xsl:attribute>			    						 	    					
				    					</xsl:element>
				    					<xsl:element name="code">
				    						<xsl:attribute name="value">			    					
				    							<xsl:value-of select="./v3:code/@code"></xsl:value-of>			    					
				    						</xsl:attribute>			    						 	    					
				    					</xsl:element>
				    					<xsl:element name="display">
				    						<xsl:attribute name="value">			    					
				    							<xsl:value-of select="./v3:code/@displayName"></xsl:value-of>			    					
				    						</xsl:attribute>			    						 	    					
				    					</xsl:element>	    				
				    				</xsl:element>	
				    			</xsl:element>    			
			    			
			    			</xsl:for-each>			
							
						</xsl:element>	
					</xsl:element>	
				</xsl:element>
		
		</xsl:for-each>
		
	</xsl:template>	<!-- end of Business operation template -->
	
	
	
</xsl:transform>