package integration.type

import org.junit.Before
import org.junit.ClassRule
import org.junit.Test
import testcommon.AbstractRatPackTest
import testcommon.docker.DockerContainerResource

import static com.jayway.restassured.RestAssured.given
import static config.AppConstants.OK
import static config.AppConstants.applicationAtomXml
import static org.hamcrest.Matchers.*
import static testcommon.TestConstants.EMPTY_DOCKER_IMAGE

class TestType extends AbstractRatPackTest
{
	@ClassRule
	public static DockerContainerResource docker = dockerContainerResourceFor (EMPTY_DOCKER_IMAGE)

	@Before
	public void setup()
	{
		insurePrefix ('ost', 'http://rdf.overstory.co.uk/rdf/terms/')
		insurePrefix ('foaf', 'http://xmlns.com/foaf/0.1/')
		insurePrefix ('dc', 'http://purl.org/dc/terms/')
		insurePrefix ('org', 'http://www.w3.org/ns/org#')

		loadTestRecordByUri ('urn:overstory.co.uk:id:person:test_record')
	}

	@Test
	public void shouldReturnTypeList()
	{
		given()
			.config (raXmlConfig())
			.header ("Accept", applicationAtomXml)
		.when()
			.get ("/rdf/record/type")
		.then()
			.log ().ifStatusCodeMatches (not (OK))
			.statusCode (OK)
			.contentType (applicationAtomXml)
			.body (not (empty()))
			.body (hasXPath ('/atom:feed', namespaces))
			.body (hasXPath ("/atom:feed/atom:id", namespaces, equalTo ("/rdf/record/type")))
			.body (hasXPath ('/atom:feed/oss:pagination', namespaces))

	}
}
