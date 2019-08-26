<?xml version = "1.0" encoding = "UTF-8"?>
<xsl:stylesheet version="2.0"
	xmlns:f="http://hl7.org/fhir" xmlns="urn:hl7-org:v3"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:output method='xml' encoding="UTF-8" indent="yes" />
	<!-- <xsl:strip-space elements="*"/> -->

	<!-- Main Template............................................................... -->
	<xsl:template match="/f:Bundle">

		<xsl:processing-instruction
			name="xml-stylesheet">
			<xsl:text>href="http://www.accessdata.fda.gov/spl/stylesheet/spl.xsl" type="text/xsl"</xsl:text>
		</xsl:processing-instruction>

		<document xmlns="urn:hl7-org:v3"
			xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="urn:hl7-org:v3 http://www.accessdata.fda.gov/spl/schema/spl.xsd">
			
			<xsl:apply-templates select="/f:Bundle/f:id" />
			<xsl:call-template name="Bundle-code" />
			<xsl:apply-templates
				select="/f:Bundle/f:entry/f:resource/f:Composition/f:date" />
			<xsl:apply-templates
				select="/f:Bundle/f:entry/f:resource/f:Composition/f:identifier/f:value" />
			<xsl:apply-templates
				select="/f:Bundle/f:entry/f:resource/f:Composition/f:meta/f:versionId" />
				
			<xsl:call-template name="Author" />

		</document>
	</xsl:template>

	<!-- Templates................................................................. -->

	<xsl:template match="f:Bundle/f:id">
		<id>
			<xsl:attribute name="root">
    	     	<xsl:value-of select="@value" />
	    	</xsl:attribute>
		</id>
	</xsl:template>

	<!-- Bundle-code............................................................. -->

	<xsl:template name="Bundle-code">
		<code code="51725-0" codeSystem="2.16.840.1.113883.6.1"
			displayName="ESTABLISHMENT REGISTRATION" />
		<title/>
	</xsl:template>

	<!-- ......................................................................... -->

	<xsl:template
		match="/f:Bundle/f:entry/f:resource/f:Composition/f:date">
		<xsl:element name="effectiveTime">
			<xsl:attribute name="value">
    	     	<xsl:value-of select="concat(substring(@value,1,4), substring(@value,6,2), substring(@value,9,2))" />
	    	</xsl:attribute>
		</xsl:element>
	</xsl:template>

	<!-- ......................................................................... -->

	<xsl:template
		match="/f:Bundle/f:entry/f:resource/f:Composition/f:identifier/f:value">
		<xsl:element name="setId">
			<xsl:attribute name="root">
    	     	<xsl:value-of select="substring(@value,10)" />
	    	</xsl:attribute>
		</xsl:element>
	</xsl:template>

	<!-- ......................................................................... -->

	<xsl:template
		match="/f:Bundle/f:entry/f:resource/f:Composition/f:meta/f:versionId" >
		<xsl:element name="versionNumber">
			<xsl:attribute name="value">
    	     	<xsl:value-of select="@value" />
	    	</xsl:attribute>
		</xsl:element>
	</xsl:template>

	<!-- Author........ 1.1  ........................................................... -->

	<xsl:template name="Author">
		<author>
			<time />
			<assignedEntity>
				<representedOrganization>
					<assignedEntity>
						<assignedOrganization>

							<xsl:call-template name="Registrant" />

							<xsl:for-each
								select="//f:resource/f:Composition/f:section/f:entry">
								<xsl:variable name="EST"
									select="substring(f:reference/@value,14)" />
								<!-- EST-:<xsl:value-of select="$EST" /> -->

								<assignedEntity>

									<xsl:for-each
										select="//f:resource/f:Organization[f:id/@value=$EST]">
										
										<xsl:call-template name="Establishment" />
										
										<!-- ORGx- : <xsl:value-of select="f:reference/@value" /> -->
									</xsl:for-each>

									<!-- ORGx-: <xsl:value-of select="f:reference/@value" /> -->
									<xsl:call-template name="EST-Performance" />

								</assignedEntity>

							</xsl:for-each>

						</assignedOrganization>
					</assignedEntity>
				</representedOrganization>
			</assignedEntity>
		</author>
		<component>
			<nonXMLBody>
				<text />
			</nonXMLBody>
		</component>
	</xsl:template>

	<!-- Registrant........... 1.1 ........................................................ -->

	<xsl:template name="Registrant">
		<id
			extension="{/f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:identifier/f:value/@value }"
			root="1.3.6.1.4.1.519.1" />
		<name>
			<xsl:value-of
				select="/f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:name/@value" />
		</name>
		<contactParty>
			<addr>
				<streetAddressLine>
					<xsl:value-of
						select="/f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:contact/f:address/f:line/@value" />
				</streetAddressLine>

				<xsl:if
					test="/f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:contact/f:address/f:line[2]/@value">
					<streetAddressLine>
					<xsl:value-of
						select="/f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:contact/f:address/f:line[2]/@value"/>
					</streetAddressLine>
				</xsl:if>

				<city>
					<xsl:value-of
						select="/f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:contact/f:address/f:city/@value" />
				</city>
				<xsl:if
					test="/f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:contact/f:address/f:state/@value">
					<state>
						<xsl:value-of
							select="/f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:contact/f:address/f:state/@value" />
					</state>
				</xsl:if>

				<xsl:if
					test="/f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:contact/f:address/f:postalCode/@value">
					<postalCode>
						<xsl:value-of
							select="/f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:contact/f:address/f:postalCode/@value" />
					</postalCode>
				</xsl:if>
				<country >
					<xsl:value-of
						select="/f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:contact/f:address/f:country/@value" />
				</country>
			</addr>
			<telecom
				value="{concat('tel:', /f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:contact/f:telecom[1]/f:value/@value)}" />
			<telecom
				value="{concat('mailto:', /f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:contact/f:telecom[2]/f:value/@value)}" />
			<xsl:if
				test="/f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:contact/f:telecom[3]/f:value/@value">
				<telecom
					value="{concat('fax:', /f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:contact/f:telecom[3]/f:value/@value)}" />
			</xsl:if>
			<contactPerson>
				<name>
					<xsl:value-of
						select="/f:Bundle/f:entry/f:resource/f:Composition/f:contained/f:Organization/f:contact/f:name/f:text/@value" />
				</name>
			</contactPerson>
		</contactParty>
	</xsl:template>

	<!-- Establishment...... 1.* ....................................... -->

	<xsl:template name="Establishment">

		<xsl:variable name="EST" select="f:id/@value" />
		<!-- **********EST: <xsl:value-of select="$EST" /> -->

		<assignedOrganization>
			<id extension="{f:identifier[1]/f:value/@value}"
				root="1.3.6.1.4.1.519.1" />
			<xsl:if test="f:identifier[2]/f:value/@value ">
				<id extension="{f:identifier[2]/f:value/@value }"
					root="2.16.840.1.113883.4.82" />
			</xsl:if>
			<name>
				<xsl:value-of select="f:name/@value" />
			</name>
			<addr>
				<streetAddressLine>
					<xsl:value-of select="f:address/f:line[1]/@value" />
				</streetAddressLine>
				<xsl:if test="f:address/f:line[2]/@value">
					<streetAddressLine>
						<xsl:value-of select="f:address/f:line[2]/@value" />
					</streetAddressLine>
				</xsl:if>
				<city>
					<xsl:value-of select="f:address/f:city/@value" />
				</city>
				<xsl:if test="f:address/f:state/@value">
					<state>
						<xsl:value-of select="f:address/f:state/@value" />
					</state>
				</xsl:if>
				<postalCode>
					<xsl:value-of select="f:address/f:postalCode/@value" />
				</postalCode>
				<country >
					<xsl:value-of select="f:address/f:country/@value" />
				</country>
			</addr>
			<contactParty>
				<addr>
					<streetAddressLine>
						<xsl:value-of
							select="f:contact/f:address/f:line/@value" />
					</streetAddressLine>
					<xsl:if test="f:contact/f:address/f:line[2]/@value">
						<streetAddressLine>
							<xsl:value-of
								select="f:contact/f:address/f:line[2]/@value" />
						</streetAddressLine>
					</xsl:if>
					<city>
						<xsl:value-of
							select="f:contact/f:address/f:city/@value" />
					</city>
					<xsl:if test="f:contact/f:address/f:state/@value">
						<state>
							<xsl:value-of
								select="f:contact/f:address/f:state/@value" />
						</state>
					</xsl:if>
					<xsl:if test="f:contact/f:address/f:postalCode/@value">
						<postalCode>
							<xsl:value-of
								select="f:contact/f:address/f:postalCode/@value" />
						</postalCode>
					</xsl:if>
					<country>
						<xsl:value-of
							select="f:contact/f:address/f:country/@value" />
					</country>
				</addr>
				<telecom
					value="{concat('tel:', f:contact/f:telecom[1]/f:value/@value)}" />
				<telecom
					value="{concat('mailto:', f:contact/f:telecom[2]/f:value/@value)}" />
				<xsl:if test="f:contact/f:telecom[3]/f:value/@value ">
					<telecom
						value="{concat('fax:', f:contact/f:telecom[3]/f:value/@value)}" />

				</xsl:if>



				<contactPerson>
					<name>
						<xsl:value-of select="f:contact/f:name/f:text/@value" />
					</name>
				</contactPerson>
			</contactParty>

			<xsl:variable name="EST-X"
				select="concat('Organization/', $EST)" />

			<xsl:for-each
				select="/f:Bundle/f:entry/f:resource/f:OrganizationAffiliation[f:organization/f:reference/@value=$EST-X] ">

				<xsl:call-template name="OrganizationAffiliation" />

			</xsl:for-each>

		</assignedOrganization>

	</xsl:template>

	<!-- OrganizationAffiliation ..... 0.*  .................................... -->

	<xsl:template name="OrganizationAffiliation">

		<assignedEntity>

			<xsl:variable name="EST-PARTICIPANT"
				select="substring(f:participatingOrganization/f:reference/@value,14)" />
			<xsl:variable name="EST-PARTICIPANT-X"
				select="f:participatingOrganization/f:reference/@value" />
			<xsl:variable name="ORG"
				select="f:organization/f:reference/@value " />

			<xsl:for-each
				select="/f:Bundle/f:entry/f:resource/f:Organization[f:id/@value=$EST-PARTICIPANT] ">

				<xsl:call-template name="Organization" />

				<xsl:for-each
					select="//f:OrganizationAffiliation[f:organization/f:reference/@value=$ORG]">

					<xsl:if
						test="f:participatingOrganization/f:reference[@value=$EST-PARTICIPANT-X]">

						<performance>
							<actDefinition>

								<xsl:choose>
									<xsl:when test="f:code/f:text/@value = 'USAGENT'">
										<code code="C73330"
											codeSystem="2.16.840.1.113883.3.26.1.1"
											displayName="UNITED STATES AGENT" />
									</xsl:when>
									<xsl:otherwise>
										<code code="C73599"
											codeSystem="2.16.840.1.113883.3.26.1.1" displayName="IMPORT" />
									</xsl:otherwise>
								</xsl:choose>
							</actDefinition>
						</performance>
					</xsl:if>
				</xsl:for-each>

			</xsl:for-each>

		</assignedEntity>
	</xsl:template>

	<!-- Organization ......... 0.* ........................................... -->

	<xsl:template name="Organization">

		<assignedOrganization>
			<id extension="{f:identifier/f:value/@value}"
				root="1.3.6.1.4.1.519.1" />
			<name>
				<xsl:value-of select="f:name/@value" />
			</name>
			<telecom
				value="{concat('tel:', f:telecom[1]/f:value/@value)}" />
			<telecom
				value="{concat('mailto:', f:telecom[2]/f:value/@value)}" />
		</assignedOrganization>

	</xsl:template>

	<!-- EST-Performance ........... 1.* ......................................... -->

	<xsl:template name="EST-Performance">

		<xsl:variable name="ORG" select="f:reference/@value" />
		<xsl:for-each
			select="/f:Bundle/f:entry/f:resource/f:HealthcareService[f:providedBy/f:reference/@value=$ORG]">
			<performance>
				<actDefinition>

					<code code="{f:type/f:coding/f:code/@value}"
						codeSystem="2.16.840.1.113883.3.26.1.1"
						displayName="{f:type/f:coding/f:display/@value}" />
					<xsl:for-each select="f:specialty">
						<subjectOf>
							<approval>
								<code code="{f:coding/f:code/@value}"
									codeSystem="2.16.840.1.113883.3.26.1.1"
									displayName="{f:coding/f:display/@value}" />
							</approval>
						</subjectOf>
					</xsl:for-each>

				</actDefinition>
			</performance>

		</xsl:for-each>

	</xsl:template>

</xsl:stylesheet>