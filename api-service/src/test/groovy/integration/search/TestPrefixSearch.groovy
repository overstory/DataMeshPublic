package integration.search

import org.junit.Before
import org.junit.ClassRule
import org.junit.Test
import testcommon.AbstractRatPackTest
import testcommon.docker.DockerContainerResource

import static com.jayway.restassured.RestAssured.given
import static org.hamcrest.Matchers.*
import static testcommon.TestConstants.EMPTY_DOCKER_IMAGE

class TestPrefixSearch extends AbstractRatPackTest
{
	@ClassRule
	public static DockerContainerResource docker = dockerContainerResourceFor (EMPTY_DOCKER_IMAGE)

	private static final String type = "ost:Prefix"

	@Before
	void setup()
	{
		loadPrefixesFromFile ('test-prefixes/prefixes.txt')
	}

	@Test
	public void shouldReturnPrefixTypes()
	{
		given()
			.config (raXmlConfig())
			.header ("Accept", "application/atom+xml")
		.when()
			.get ("/record/type/${type}")
		.then()
			.log ().ifStatusCodeMatches (not (200))
			.statusCode (200)
			.contentType ("application/atom+xml")
			.body (not (empty()))
			.body (hasXPath ("/atom:feed/atom:id", namespaces, equalTo ("/record/type/ost:Prefix")))
			.body (hasXPath ('/atom:feed/oss:search-criteria', namespaces))
//			.body (hasXPath ('/atom:feed/oss:pagination', namespaces))
			.body (not(hasXPath ('/atom:feed/atom:entry', namespaces)))
	}

	@Test
	public void shouldReturnPrefixTypesAll()
	{
		given()
			.config (raXmlConfig())
			.header ("Accept", "application/atom+xml")
			.param ("search-all", "true")
		.when()
			.get ("/record/type/${type}")
		.then()
			.log ().ifStatusCodeMatches (not (200))
			.statusCode (200)
			.contentType ("application/atom+xml")
			.body (not (empty()))
			.body (hasXPath ("/atom:feed/atom:id", namespaces, equalTo ("/record/type/ost:Prefix?search-all=true")))
			.body (hasXPath ('/atom:feed/oss:search-criteria', namespaces))
//			.body (hasXPath ('/atom:feed/oss:pagination', namespaces))
			.body (hasXPath ('/atom:feed/atom:entry', namespaces))

	}

}

