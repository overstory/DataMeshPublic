package testcommon

import config.AppConfigBuilder
import org.junit.After
import org.junit.Before
import ratpack.groovy.GroovyRatpackMain
import ratpack.test.MainClassApplicationUnderTest
import ratpack.test.ServerBackedApplicationUnderTest
import testcommon.docker.DockerContainerResource
import testcommon.docker.DockerMarkLogic

import static com.jayway.restassured.RestAssured.baseURI
import static com.jayway.restassured.RestAssured.given
import static com.jayway.restassured.RestAssured.registerParser
import static config.AppConstants.*
import static org.hamcrest.Matchers.isIn
import static org.hamcrest.Matchers.not
import static org.hamcrest.Matchers.notNullValue

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 10/7/16
 * Time: 9:58 PM
 */
class AbstractRatPackTest extends AbstractTest
{
	ServerBackedApplicationUnderTest aut

	@Before
	void setupRestAssured ()
	{
		AdditionalProperties additionalProperties = this.getClass ().getAnnotation (AdditionalProperties)
		String[] propertyFiles = additionalProperties ? additionalProperties.value () : []

		propertyFiles.each {
			AppConfigBuilder.addPropertyFile (it)
		}

		aut = new MainClassApplicationUnderTest (GroovyRatpackMain)
		baseURI = aut.address

		contentParseMap.each { String parser, List<String> types ->
			types.each { mime ->
				registerParser (mime, parserNameMap [parser])
			}
		}
	}

	@After
	void tearDown ()
	{
		if (aut != null) aut.stop ()
		AppConfigBuilder.clearProperties ()
	}

	static DockerContainerResource dockerContainerResourceFor (String imageName)
	{
		def config = AppConfigBuilder.appConfig ()

		DockerMarkLogic dml = new DockerMarkLogic (
			image: imageName,
			user: config.get (appPropertyName).docker.mluser,
			password: config.get (appPropertyName).docker.mlpassword,
			testPort: (testDockerPort == -1) ? config.get (appPropertyName).xmlreposervice.port : testDockerPort,
			volume: (testDockerVolume == null) ? config.get (appPropertyName).docker.appserverRoot : testDockerVolume,
			hostName: config.get (appPropertyName).docker.dockerHostName,
			certDirectory: config.get (appPropertyName).docker.dockerCertDir,
			dockerUser: config.get (appPropertyName).docker.dockerUsername,
			dockerPassword: config.get (appPropertyName).docker.dockerPassword,
			dockerEmail: config.get (appPropertyName).docker.dockerEmail)

		new DockerContainerResource (dml)
	}

	static void insurePrefix (String prefix, String ns)
	{
		given ()
			.config (raXmlConfig ())
			.header ("Accept", "application/vnd.overstory.record+xml")
			.body (ns)
			.contentType (textPlain)
			.when ()
			.put ("/rdf/prefix/${prefix}")
			.then ()
			.log ().ifStatusCodeMatches (not (isIn (OK, Created, Conflict)))
			.statusCode (isIn (OK, Created, Conflict))

	}

	static String getEtagForUri (String uri)
	{
		given()
			.config (raXmlConfig())
		.when()
			.head (uri)
		.then()
			.log().ifStatusCodeMatches (not (isIn (OK, NotFound)))
			.statusCode (isIn (OK, NotFound))
		.extract()
			.header ("ETag")
	}

	void loadTestRecordByUri (String uri)
	{
		given()
			.config (raXmlConfig())
			.body (testDataRecordAsStream ("${uri}.xml").text)
			.contentType (applicationXml)
			.accept (applicationXml)
		.when()
			.put ("/record/id/${uri}")
		.then()
			.log().ifStatusCodeMatches (not(isIn (Created, Conflict)))
			.statusCode (isIn (Created, Conflict))
	}

	void insureTestRecordByUri (String uri)
	{
		String etag = getEtagForUri (uri)

		if ( ! etag) {
			loadTestRecordByUri (uri)
		}

		if (etag) {
			given()
				.config (raXmlConfig())
				.body (testDataRecordAsStream ("${uri}.xml").text)
				.contentType (applicationXml)
				.accept (applicationXml)
			.when()
				.put ("/record/id/${uri}")
			.then()
				.log().ifStatusCodeMatches (not(isIn (Created, Conflict)))
				.statusCode (isIn (Created, Conflict))
		}

	}
}
