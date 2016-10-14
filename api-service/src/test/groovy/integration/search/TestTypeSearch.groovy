package integration.search

import org.junit.Before
import org.junit.ClassRule
import org.junit.Test
import testcommon.AbstractRatPackTest
import testcommon.docker.DockerContainerResource

import static com.jayway.restassured.RestAssured.given
import static org.hamcrest.Matchers.*
import static testcommon.TestConstants.EMPTY_DOCKER_IMAGE

class TestTypeSearch extends AbstractRatPackTest
{
	@ClassRule
	public static DockerContainerResource docker = dockerContainerResourceFor (EMPTY_DOCKER_IMAGE)

	private static final String type = "ost:Prefix"

	@Before
	void setup()
	{
		loadPrefixesFromFile ('test-prefixes/prefixes.txt')
		insureTestRecordByUri ('urn:overstory.co.uk:id:person:test_record')
	}

	@Test
	public void shouldReturnPersonType()
	{
		String type = "foaf:Person"

		given()
			.config (raXmlConfig())
			.header ("Accept", "application/atom+xml")
		.when()
			.get ("/record/type/${type}")
		.then()
			.log().ifStatusCodeMatches (not (200))
			.statusCode (200)
			.contentType ("application/atom+xml")
			.body (not (empty()))
			.body (hasXPath ("/atom:feed/atom:id", namespaces, equalTo ("/record/type/foaf:Person")))
			.body (hasXPath ('/atom:feed/oss:search-criteria', namespaces))
//			.body (hasXPath ('/atom:feed/oss:pagination', namespaces))
			.body (hasXPath ('/atom:feed/atom:entry', namespaces))
	}
}

