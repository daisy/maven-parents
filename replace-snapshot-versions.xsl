<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:pom="http://maven.apache.org/POM/4.0.0"
                xmlns="http://maven.apache.org/POM/4.0.0"
                xpath-default-namespace="http://maven.apache.org/POM/4.0.0">
	
	<xsl:param name="BRANCH"/>
	<xsl:param name="OUTPUT_FILENAME"/>
	
	<xsl:variable name="BASE" select="base-uri(/*)"/>
	
	<xsl:output method="xml"/>
	
	<xsl:template match="/">
		<xsl:variable name="internal-artifacts" as="element()*">
			<xsl:apply-templates mode="internal-artifacts" select="*">
				<xsl:with-param name="module" tunnel="yes" select="'.'"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:result-document href="{$OUTPUT_FILENAME}" method="xml">
			<xsl:text>&#x0A;</xsl:text>
			<xsl:apply-templates select="*">
				<xsl:with-param name="module" tunnel="yes" select="'.'"/>
				<xsl:with-param name="internal-artifacts" tunnel="yes" select="$internal-artifacts"/>
			</xsl:apply-templates>
		</xsl:result-document>
	</xsl:template>
	
	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="version[ends-with(.,'-SNAPSHOT')]">
		<xsl:param name="internal-artifacts" tunnel="yes"/>
		<xsl:copy>
			<xsl:choose>
				<xsl:when test="parent::project
				                or $internal-artifacts[string(groupId)=string(current()/parent::*/groupId) and
				                                       string(artifactId)=string(current()/parent::*/artifactId)]">
					<xsl:value-of select="replace(string(.),'^(.+)-SNAPSHOT$',concat('$1-',$BRANCH,'-SNAPSHOT'))"/>
				</xsl:when>
				<!--
				    version ranges not supported in maven-dependency-plugin
				-->
				<xsl:when test="parent::artifactItem/parent::artifactItems/parent::configuration/parent::execution/parent::executions
				                /parent::plugin[string(artifactId)='maven-dependency-plugin'
				                                and (not(groupId) or string(groupId)='org.apache.maven.plugins')]">
					<xsl:value-of select="replace(string(.),'^(.+)-SNAPSHOT$',concat('$1-',$BRANCH,'-SNAPSHOT'))"/>
				</xsl:when>
				<!--
				    for now don't support dependencies to external parents (e.g. modules-parent)
				    because versions-maven-plugin does not handle version ranges in a parent
				-->
				<xsl:when test="parent::parent">
					<xsl:value-of select="string(.)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="replace(string(.),'^(.+)-SNAPSHOT$',concat('[$1-SNAPSHOT],[$1-',$BRANCH,'-SNAPSHOT]'))"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:copy>
	</xsl:template>
	
	<!--
	    versions-maven-plugin:resolve-ranges does not work for import dependencies. A workaround is
	    to create copies of the import dependencies but without the scope.
	-->
	<xsl:template match="/project/dependencyManagement/dependencies/dependency[string(scope)='import']">
		<xsl:param name="internal-artifacts" tunnel="yes"/>
		<xsl:next-match/>
		<xsl:if test="not($internal-artifacts[string(groupId)=string(current()/groupId) and
		                                      string(artifactId)=string(current()/artifactId)])">
			<xsl:next-match>
				<xsl:with-param name="delete-scope" tunnel="yes" select="true()"/>
			</xsl:next-match>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="dependency/scope">
		<xsl:param name="delete-scope" tunnel="yes" select="false()"/>
		<xsl:if test="not($delete-scope)">
			<xsl:next-match/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="/project/modules/module">
		<xsl:param name="module" tunnel="yes" required="yes"/>
		<xsl:variable name="submodule" select="string-join((
		                                         if ($module='.') then () else $module,
		                                         string(.)),'/')"/>
		<xsl:variable name="submodule-pom" select="document(resolve-uri(concat($submodule,'/pom.xml'),$BASE))"/>
		<xsl:result-document href="{concat($submodule,'/',$OUTPUT_FILENAME)}" method="xml">
			<xsl:text>&#x0A;</xsl:text>
			<xsl:apply-templates select="$submodule-pom/*">
				<xsl:with-param name="module" tunnel="yes" select="$submodule"/>
			</xsl:apply-templates>
		</xsl:result-document>
		<xsl:next-match/>
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
