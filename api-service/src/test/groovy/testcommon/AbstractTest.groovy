package testcommon

import com.jayway.restassured.config.RestAssuredConfig
import com.jayway.restassured.parsing.Parser
import com.jayway.restassured.path.xml.config.XmlPathConfig
import config.AppConfigBuilder

import static com.jayway.restassured.config.RestAssuredConfig.newConfig;
import static com.jayway.restassured.config.XmlConfig.xmlConfig;

import javax.xml.namespace.NamespaceContext
import static config.AppConstants.*

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 10/7/16
 * Time: 9:54 PM
 */
class AbstractTest
{
	public AbstractCupTest()
	{
		AppConfigBuilder.loadLogback()
	}

	// content-types that should be parsed as XML
	static final List<String> xmlMimeTypes = [
		applicationXml, errorXmlContentType, applicationCollectionsXml, applicationAtomXml, applicationDataMeshMetaXml, applicationDataMeshRecordXml
	]
	// content-types that should be parsed as JSON
	static final List<String> jsonMimeTypes = [
		errorJsonContentType, applicationJson, applicationCollectionsJson, applicationDataMeshMetaJson, applicationDataMeshRecordJson
	]

	// map of content-type lists that should be registered, grouped by Parser, add TEXT and/or HTML lists if needed
	static final Map<String,List<String>> contentParseMap = [
		"XML" : xmlMimeTypes, "JSON" : jsonMimeTypes
	]
	static final Map<String,Parser> parserNameMap = [
		"XML" : Parser.XML, "JSON" : Parser.JSON, "HTML" : Parser.HTML, "TEXT" : Parser.TEXT
	]

	// namespaces that XML parsing should know about
	static final Map<String,String> namespaceMap = [
		"xsl" : "http://www.w3.org/1999/XSL/Transform",
		"xlink" : "http://www.w3.org/1999/xlink",
		"atom" : "http://www.w3.org/2005/Atom",
		"html" : "http://www.w3.org/1999/xhtml",
		"e" : "http://ns.overstory.co.uk/namespaces/error",
		"osc" : "http://ns.overstory.co.uk/namespaces/datamesh/content",
		"oss" : "http://ns.overstory.co.uk/namespaces/search",
		"vcard" : "http://www.w3.org/2006/vcard/ns#",
		"sparql" : "http://www.w3.org/2005/sparql-results#"
	]
	public static final NamespaceContext namespaces = new SimpleNamespaceContext (namespaceMap)

	// -------------------------------------------------------------

	static final ConfigObject configObject = AppConfigBuilder.appConfig()
//	static ConfigData configData = ConfigData.builder().props (configObject.toProperties()).env().sysProps().build()

	static int testDockerPort = configObject.get (appPropertyName).xmlreposervice.port
	static String testDockerVolume = configObject.get (appPropertyName).docker.appserverRoot

	// -------------------------------------------------------------

	// Creates an XML config that defines the namespaces listed above, and enables namespace-aware processing
	static RestAssuredConfig raXmlConfig()
	{
		return newConfig()
		//.encoderConfig(encoderConfig().defaultContentCharset("UTF-8"))
			.xmlConfig (xmlConfig().declareNamespaces (namespaceMap))
	}

	// ------------------------------------------------------------

	static XmlPathConfig raXmlPathConfig()
	{
		return XmlPathConfig.xmlPathConfig().declareNamespaces(namespaceMap)
	}

	protected InputStream testDataAsStream (String filename)
	{
		return getClass().classLoader.getResourceAsStream (filename)
	}

	protected InputStream testDataRecordAsStream (String filename)
	{
		return testDataAsStream ("test-records${File.separator}${filename}")
	}

	protected File testDataRecordAsFile (String filename)
	{
		new File (getClass().classLoader.getResource ("test-records${File.separator}${filename}").toURI())
	}

	// ------------------------------------------------------------

	public static class SimpleNamespaceContext implements NamespaceContext
	{
		private final Map<String,String> nsmap;

		SimpleNamespaceContext (nsmap)
		{
			this.nsmap = nsmap
		}

		@Override
		String getNamespaceURI (String prefix)
		{
			return nsmap.get (prefix)
		}

		@Override
		String getPrefix (String namespaceURI)
		{
			for (Map.Entry entry : nsmap.entrySet()) {
				if (entry.value.equals (namespaceURI)) return entry.key
			}

			return null
		}

		@Override
		Iterator getPrefixes (String namespaceURI)
		{
			return nsmap.keySet().iterator()
		}
	}
}
