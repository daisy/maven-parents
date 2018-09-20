<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pom="http://maven.apache.org/POM/4.0.0"
                xmlns="http://maven.apache.org/POM/4.0.0"
                xpath-default-namespace="http://maven.apache.org/POM/4.0.0">
	
	<xsl:output method="text"/>
	
	<xsl:variable name="BASE" select="base-uri(/*)"/>
	
	<xsl:template match="/">
		<xsl:variable name="internal-artifacts" as="element()*">
			<xsl:apply-templates mode="internal-artifacts" select="*">
				<xsl:with-param name="module" tunnel="yes" select="'.'"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:variable name="internal-artifacts" as="xs:string*"
		              select="for $a in $internal-artifacts return concat($a/groupId,':',$a/artifactId,':',$a/version)"/>
		<xsl:variable name="snapshot-dependencies" as="xs:string*">
			<xsl:apply-templates select="*">
				<xsl:with-param name="module" tunnel="yes" select="'.'"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:variable name="snapshot-dependencies" as="xs:string*" select="$snapshot-dependencies[not(.=$internal-artifacts)]"/>
		<xsl:if test="exists($snapshot-dependencies)">
			<xsl:variable name="snapshot-dependencies" select="distinct-values($snapshot-dependencies)"/>
			<xsl:text>Snapshot dependencies used for this build:</xsl:text>
			<xsl:text>&#x0A;</xsl:text>
			<xsl:for-each select="$snapshot-dependencies">
				<xsl:sort order="ascending"/>
				<xsl:text>* </xsl:text>
				<xsl:value-of select="."/>
				<xsl:text>&#x0A;</xsl:text>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="*" as="xs:string*">
		<xsl:apply-templates select="*"/>
	</xsl:template>
	
	<xsl:template match="version[not(parent::project) and ends-with(.,'-SNAPSHOT') and parent::*/artifactId]">
		<xsl:sequence select="concat(parent::*/groupId,':',parent::*/artifactId,':',.)"/>
	</xsl:template>
		
	<xsl:template match="/project/modules/module">
		<xsl:param name="module" tunnel="yes" required="yes"/>
		<xsl:variable name="submodule" select="string-join((if ($module='.') then () else $module,string(.)),'/')"/>
		<xsl:apply-templates select="document(resolve-uri(concat($submodule,'/pom.xml'),$BASE))/*">
			<xsl:with-param name="module" tunnel="yes" select="$submodule"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<xsl:template mode="internal-artifacts" match="/project">
		<artifactItem>
			<xsl:sequence select="(groupId,parent/groupId)[1],artifactId,version"/>
		</artifactItem>
		<xsl:apply-templates mode="#current" select="modules/module"/>
	</xsl:template>
	
	<xsl:template mode="internal-artifacts" match="/project/modules/module">
		<xsl:param name="module" tunnel="yes" required="yes"/>
		<xsl:variable name="submodule" select="string-join((
		                                         if ($module='.') then () else $module,
		                                         string(.)),'/')"/>
		<xsl:variable name="submodule-pom" select="document(resolve-uri(concat($submodule,'/pom.xml'),$BASE))"/>
		<xsl:apply-templates mode="#current" select="$submodule-pom/*">
			<xsl:with-param name="module" tunnel="yes" select="$submodule"/>
		</xsl:apply-templates>
	</xsl:template>
	
</xsl:stylesheet>
