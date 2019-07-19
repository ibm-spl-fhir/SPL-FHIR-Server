<?xml version="1.0" encoding="UTF-8"?>
<xsl:transform version="2.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:v3="http://hl7.org/fhir" 
    xmlns:v="http://validator.pragmaticdata.com/result" 
    xmlns:str="http://exslt.org/strings" 
    xmlns:exsl="http://exslt.org/common" 
    xmlns:msxsl="urn:schemas-microsoft-com:xslt" 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
    exclude-result-prefixes="exsl msxsl v3 xsl xsi str v">
    
    <xsl:import href="xml-verbatim.xsl"/>
    <xsl:param name="root" select="/"/>
    <xsl:param name="css" select="'./fhir.css'"/>
    <xsl:param name="show-subjects-xml" select="/.."/>
    <xsl:param name="show-data" select="1"/>
    <xsl:param name="show-section-numbers" select="/.."/>
    <xsl:param name="update-check-url-base" select="/.."/>
    <xsl:param name="process-mixins" select="/.."/>
    <xsl:param name="standardSections" select="document('plr-sections.xml')/*"/>
    <xsl:param name="itemCodeSystems" select="document('item-code-systems.xml')/*"/>
    <xsl:param name="disclaimers" select="document('disclaimers.xml')/*"/>
    <xsl:param name="documentTypes" select="document('doc-types.xml')/*"/>
    <xsl:param name="indexingDocumentTypes" select="document('indexing-doc-types.xml')/*"/>
    <xsl:output method="html" encoding="UTF-8" indent="no" doctype-public="-"/>
    <xsl:strip-space elements="*"/>

    <!-- MAIN MODE based on the deep null-transform -->
    <xsl:template match="/|@*|node()">
        <xsl:apply-templates select="@*|node()"/>
    </xsl:template>
 
    <xsl:template match="/v3:Bundle">
        <!-- GS: this template needs thorough refactoring -->
        <html>
            <head>
                <meta name="documentId" content="{/v3:Bundle/v3:entry/v3:resource/v3:Composition/v3:identifier/v3:value/@value}"/>
                <meta name="documentSetId" content="{/v3:Bundle/v3:entry/v3:resource/v3:Composition/v3:extension/v3:extension[@url='setID']/v3:valueIdentifier/v3:value/@value}"/>
                <meta name="documentVersionNumber" content="{/v3:Bundle/v3:entry/v3:resource/v3:Composition/v3:extension/v3:extension[@url='versionNumber']/v3:valueString/@value}"/>
                <meta name="documentEffectiveTime" content="{/v3:Bundle/v3:entry/v3:resource/v3:Composition/v3:date/@value}"/>
                <title><!-- GS: this isn't right because the title can have markup -->
                    <xsl:value-of select="v3:entry/v3:resource/v3:Composition/v3:title"/>
                </title>
                <link rel="stylesheet" type="text/css" href="{$css}"/>
            </head>
            <body class="spl" id="spl">
                <xsl:attribute name="onload"><xsl:text>if(typeof convertToTwoColumns == "function")convertToTwoColumns();</xsl:text></xsl:attribute>
                <xsl:apply-templates mode="title" select="./v3:entry/v3:resource/v3:Composition"/>
                <h1><xsl:apply-templates mode="mixed" select="v3:entry/v3:resource/v3:Composition/v3:title"/></h1>
                <div class="Contents">
                    <xsl:apply-templates select="@*|node()"/>
                </div>
                
                <xsl:if test="boolean($show-data)">
                    <div class="DataElementsTables">
                        <xsl:apply-templates mode="subjects" select="v3:entry/v3:resource/v3:Composition/v3:contained/v3:Organization"/>
                        <xsl:variable name="orgReference" select="v3:entry/v3:resource/v3:Composition/v3:section/v3:entry/v3:reference/@value"/>
						<xsl:variable name="orgEntry" select="v3:entry[$orgReference = substring(v3:fullUrl/@value, string-length(v3:fullUrl/@value) - string-length($orgReference) +1)]"/>
						
                        <xsl:apply-templates mode="subjects" select="$orgEntry/v3:resource/v3:Organization"/>
                     </div>
                </xsl:if>
                <p>
                    <xsl:call-template name="effectiveDate"/>
                </p>
                
                <xsl:if test="boolean($show-subjects-xml)">
                    <hr/>
                    <div class="Subject" onclick="xmlVerbatimClick(event);" ondblclick="xmlVerbatimDblClick(event);">
                        <xsl:apply-templates mode="xml-verbatim" select="node()"/>
                    </div>
                </xsl:if>
            </body>
        </html>
    </xsl:template>
    
    <xsl:template mode="subjects" match="//v3:Composition/v3:contained/v3:Organization">	
        <xsl:if test="./v3:name">
            <table width="100%" cellpadding="3" cellspacing="0" class="formTableMorePetite">
                <tr>
                    <td colspan="4" class="formHeadingReg">
                        <span class="formHeadingTitle" >
                            Registrant -&#160;
                        </span><xsl:value-of select="./v3:name/@value"/><xsl:if test="./v3:identifier/v3:value"> (<xsl:value-of select="./v3:identifier/v3:value/@value"/>)</xsl:if>
                    </td>
                </tr>
                <xsl:call-template name="data-contactParty"/>
            </table>
        </xsl:if>
    </xsl:template>	
    
    <xsl:template mode="subjects" match="//v3:resource/v3:Organization">	
        <xsl:if test="./v3:name">
            <xsl:variable name="orgId" select="concat('Organization/',./v3:id/@value)"/>
            <table width="100%" cellpadding="3" cellspacing="0" class="formTableMorePetite">
                <tr>
                    <td colspan="4" class="formHeadingReg">
                        <span class="formHeadingTitle" >
                            Establishment
                        </span>
                    </td>				
                </tr>
                <tr>
                    <th scope="col" class="formTitle">Name</th>
                    <th scope="col" class="formTitle">Address</th>
                    <th scope="col" class="formTitle">ID/FEI</th>
                    <th scope="col" class="formTitle">Business Operations</th>
                </tr>
                <tr class="formTableRowAlt">
                    <td class="formItem">
                        <xsl:value-of select="./v3:name/@value"/>
                    </td>
                    <td class="formItem">	
                        <xsl:apply-templates mode="format" select="./v3:address"/>	
                    </td>
                    <!-- root = "1.3.6.1.4.1.519.1" -->
                    <td class="formItem">
                        <xsl:value-of select="./v3:identifier[v3:system/@value='urn:oid:1.3.6.1.4.1.519.1']/v3:value/@value"/>
                        <xsl:if test="./v3:identifier[v3:system/@value='urn:oid:1.3.6.1.4.1.519.1']/v3:value/@value and ./v3:identifier[not(v3:system/@value='urn:oid:1.3.6.1.4.1.519.1')]/v3:value/@value">/</xsl:if><xsl:value-of select="./v3:identifier[not(v3:system/@value='urn:oid:1.3.6.1.4.1.519.1')]/v3:value/@value"/>
                    </td>
                    <td class="formItem">
                        <xsl:for-each select="../../../v3:entry/v3:resource/v3:HealthcareService[v3:providedBy/v3:reference/@value = $orgId]">
                            <xsl:variable name="code" select="v3:type/v3:coding/v3:code/@value"/>
                            <xsl:value-of select="v3:type/v3:coding/v3:display/@value"/>
                            <xsl:for-each select="v3:specialty/v3:coding">
                                <xsl:text>(</xsl:text>
                                <xsl:value-of select="v3:display/@value"/>
                                <xsl:text>)</xsl:text>
                                <xsl:if test="position()!=last()">, </xsl:if>
                            </xsl:for-each>
                            <xsl:if test="position()!=last()">, </xsl:if>
                        </xsl:for-each>
                    </td>
                </tr>
                <xsl:call-template name="data-contactParty"/>
                <xsl:for-each select="../../../v3:entry/v3:resource/v3:Organization[concat('Organization/', v3:id/@value) = ../../../v3:entry/v3:resource/v3:OrganizationAffiliation[v3:organization/v3:reference/@value = $orgId][v3:code/v3:text/@value='USAGENT']/v3:participatingOrganization/v3:reference/@value]">
                    <xsl:if test="position() = 1">
                        <tr>
                            <th scope="col" class="formTitle">US Agent (ID)</th>
                            <th scope="col" class="formTitle">Address</th>
                            <th scope="col" class="formTitle">Telephone Number</th>
                            <th scope="col" class="formTitle">Email Address</th>
                        </tr>
                    </xsl:if>
                    <tr class="formTableRowAlt">
                        <td class="formItem">
                            <xsl:value-of select="v3:name"/>
                            <xsl:for-each select="v3:identifier/v3:value/@value">
                                <xsl:text> (</xsl:text>
                                <xsl:value-of select="."/>
                                <xsl:text>)</xsl:text>
                            </xsl:for-each>
                        </td>
                        <td class="formItem">		
                            <xsl:apply-templates mode="format" select="v3:address"/>
                        </td>
                        <td class="formItem">
                            <xsl:value-of select="v3:telecom[v3:system/@value='phone'][1]/v3:value/@value"/>
                            <xsl:for-each select="v3:telecom[v3:system/@value='fax']">
                                <br/>
                                <xsl:text>FAX: </xsl:text>
                                <xsl:value-of select="v3:value/@value"/>
                            </xsl:for-each>
                        </td>
                        <td class="formItem">
                            <xsl:value-of select="v3:telecom[v3:system/@value='email'][1]/v3:value/@value"/>
                        </td>
                    </tr>
                </xsl:for-each>
                <!-- 53617 changed to 73599 -->
                <xsl:for-each select="../../../v3:entry/v3:resource/v3:Organization[concat('Organization/', v3:id/@value) = ../../../v3:entry/v3:resource/v3:OrganizationAffiliation[v3:organization/v3:reference/@value = $orgId][v3:code/v3:text/@value='IMPORTER']/v3:participatingOrganization/v3:reference/@value]">	
                    <xsl:if test="position() = 1">
                        <tr>
                            <th scope="col" class="formTitle">Importer (ID)</th>
                            <th scope="col" class="formTitle">Address</th>
                            <th scope="col" class="formTitle">Telephone Number</th>
                            <th scope="col" class="formTitle">Email Address</th>
                        </tr>
                    </xsl:if>
                    <tr class="formTableRowAlt">
                        <td class="formItem">
                            <xsl:value-of select="v3:name"/>
                            <xsl:for-each select="v3:identifier/v3:value/@value">
                                <xsl:text> (</xsl:text>
                                <xsl:value-of select="."/>
                                <xsl:text>)</xsl:text>
                            </xsl:for-each>
                        </td>
                        <td class="formItem">		
                            <xsl:apply-templates mode="format" select="v3:address"/>
                        </td>
                        <td class="formItem">
                            <xsl:value-of select="v3:telecom[v3:system/@value='phone'][1]/v3:value/@value"/>
                            <xsl:for-each select="v3:telecom[v3:system/@value='fax']">
                                <br/>
                                <xsl:text>FAX: </xsl:text>
                                <xsl:value-of select="v3:value/@value"/>
                            </xsl:for-each>
                        </td>
                        <td class="formItem">
                            <xsl:value-of select="v3:telecom[v3:system/@value='email'][1]/v3:value/@value"/>
                        </td>
                    </tr>
                </xsl:for-each>
            </table>
        </xsl:if>
    </xsl:template>	

    <xsl:template name="data-contactParty">
        <xsl:for-each select="v3:contact">
            <xsl:if test="position() = 1">
                <tr>
                    <th scope="col" class="formTitle">Contact</th>
                    <th scope="col" class="formTitle">Address</th>
                    <th scope="col" class="formTitle">Telephone Number</th>
                    <th scope="col" class="formTitle">Email Address</th>
                </tr>
            </xsl:if>
            <tr class="formTableRowAlt">
                <td class="formItem">
                    <xsl:apply-templates mode="format" select="v3:name"/>
                </td>
                <td class="formItem">		
                    <xsl:apply-templates mode="format" select="v3:address"/>
                </td>
                <td class="formItem">
                    <xsl:value-of select="v3:telecom[v3:system/@value='phone'][1]/v3:value/@value"/>
                    <xsl:for-each select="v3:telecom[v3:system/@value='fax']">
                        <br/>
                        <xsl:text>FAX: </xsl:text>
                        <xsl:value-of select="v3:value/@value"/>
                    </xsl:for-each>
                </td>
                <td class="formItem">
                    <xsl:value-of select="v3:telecom[v3:system/@value='email'][1]/v3:value/@value"/>
                    <div style="display:none">
                        <xsl:attribute name="id"><xsl:text>contactMailId</xsl:text></xsl:attribute>
                        <xsl:value-of select="v3:telecom[v3:system/@value='email'][1]/v3:value/@value"/>
                    </div>
                </td>
            </tr>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template mode="title" match="//v3:Composition">
        <div class="DocumentTitle">
            <p class="DocumentTitle">
                <xsl:apply-templates select="./title/@*"/>
                <br/>
            </p>
            
            <xsl:value-of select="v3:type/v3:coding/v3:display/@value"/>
            <br/>
            <p>----------</p>
        </div>
    </xsl:template>
    
    <xsl:template mode="format" match="*/v3:address">
        <table>
            <tr><td>Address:</td><td><xsl:value-of select="./v3:line/@value"/></td></tr>
            <tr><td>City, State, Zip:</td>
                <td>
                    <xsl:value-of select="./v3:city/@value"/>
                    <xsl:if test="string-length(./v3:state/@value)>0">,&#160;<xsl:value-of select="./v3:state/@value"/></xsl:if>
                    <xsl:if test="string-length(./v3:postalCode/@value)>0">,&#160;<xsl:value-of select="./v3:postalCode/@value"/></xsl:if>
                </td>
            </tr>
            <tr><td>Country:</td><td><xsl:value-of select="./v3:country/@value"/></td></tr>
        </table>
    </xsl:template>

    <xsl:template mode="format" match="*/v3:name">
        <xsl:for-each select="v3:given">
            <xsl:value-of select="./@value"/>&#160;
        </xsl:for-each>
        <xsl:for-each select="v3:family">
            <xsl:value-of select="./@value"/>&#160;
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="effectiveDate">
        <div class="EffectiveDate">
            <!-- changed by Brian Suggs 11-13-05. Added the Effective Date: text back in so that people will know what this date is for. -->
            <!-- changed by Brian Suggs 08-18-06. Modified text to state "Revised:" as per PCR 528 -->
            <!-- GS: adding support for availabilityTime here -->
            <xsl:variable name="revisionTimeCandidates" select="/v3:Bundle/v3:entry/v3:resource/v3:Composition/v3:date"/>
            <xsl:variable name="revisionTime" select="$revisionTimeCandidates[@value != ''][last()]"/>
            <xsl:if test="$revisionTime">
                <xsl:text>Revised: </xsl:text>
                <!-- changed by Brian Suggs 08-18-06. The effective date will now only display the month and year in the following format MM/YYYY (e.g. 08/2006). Code changed per PCR 528 -->
                <xsl:apply-templates mode="data" select="$revisionTime">
                    <xsl:with-param name="displayMonth">true</xsl:with-param>
                    <xsl:with-param name="displayDay">false</xsl:with-param>
                    <xsl:with-param name="displayYear">true</xsl:with-param>
                    <xsl:with-param name="delimiter">/</xsl:with-param>
                </xsl:apply-templates>
                <xsl:if test="$update-check-url-base">
                    <xsl:variable name="url" select="concat($update-check-url-base, /v3:Bundle/v3:entry/v3:resource/v3:Composition/v3:extension/v3:extension[@url='setID']/v3:valueIdentifier/v3:value/@value)"/>
                    <xsl:text> </xsl:text>
                    <a href="{$url}">
                        <xsl:text>Click here to check for updated version.</xsl:text>
                    </a>
                </xsl:if>
                <div class="DocumentMetadata">
                    <div>
                        <xsl:attribute name="id"><xsl:text>docId</xsl:text></xsl:attribute>
                        <a href="javascript:toggleMixin();">
                            <xsl:text>Document Id: </xsl:text>
                        </a>
                        <xsl:value-of select="/v3:Bundle/v3:entry/v3:resource/v3:Composition/v3:identifier/v3:value/@value"/>
                    </div>
                    <div style="display:none">
                        <xsl:attribute name="id"><xsl:text>documentTypeCode</xsl:text></xsl:attribute>
                        <xsl:value-of select="/v3:document/v3:code/@code"/>
                    </div>
                    <div>
                        <xsl:attribute name="id"><xsl:text>setId</xsl:text></xsl:attribute>
                        <xsl:text>Set id: </xsl:text>
                        <xsl:value-of select="/v3:Bundle/v3:entry/v3:resource/v3:Composition/v3:extension/v3:extension[@url='setID']/v3:valueIdentifier/v3:value/@value"/>
                    </div>
                    <div>
                        <xsl:attribute name="id"><xsl:text>versionNo</xsl:text></xsl:attribute>
                        <xsl:text>Version: </xsl:text>
                        <xsl:value-of select="/v3:Bundle/v3:entry/v3:resource/v3:Composition/v3:extension/v3:extension[@url='versionNumber']/v3:valueString/@value"/>
                    </div>
                    <div>
                        <xsl:text>Effective Time: </xsl:text>
                        <xsl:value-of select="/v3:Bundle/v3:entry/v3:resource/v3:Composition/v3:date/@value"/>
                    </div>
                </div>
            </xsl:if>
        </div>
    </xsl:template>
    <xsl:template mode="data" match="*" priority="1">
        <xsl:param name="displayMonth">true</xsl:param>
        <xsl:param name="displayDay">true</xsl:param>
        <xsl:param name="displayYear">true</xsl:param>
        <xsl:param name="delimiter">/</xsl:param>
        <xsl:variable name="year" select="substring(@value,1,4)"/>
        <xsl:variable name="month" select="substring(@value,6,2)"/>
        <xsl:variable name="day" select="substring(@value,8,2)"/>
        <!-- changed by Brian Suggs 11-13-05.  Changes made to display date in MM/DD/YYYY format instead of DD/MM/YYYY format -->
        <xsl:if test="$displayMonth = 'true'">
            <xsl:choose>
                <xsl:when test="starts-with($month,'0')">
                    <xsl:value-of select="substring-after($month,'0')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$month"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="$delimiter"/>
        </xsl:if>
        <xsl:if test="$displayDay = 'true'">
            <xsl:value-of select="$day"/>
            <xsl:value-of select="$delimiter"/>
        </xsl:if>
        <xsl:if test="$displayYear = 'true'">
            <xsl:value-of select="$year"/>
        </xsl:if>
    </xsl:template>
    
</xsl:transform>