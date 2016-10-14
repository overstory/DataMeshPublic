package integration.search

import org.junit.ClassRule
import org.junit.Test
import testcommon.AbstractRatPackTest
import testcommon.docker.DockerContainerResource

import static com.jayway.restassured.RestAssured.*
import static org.hamcrest.Matchers.*
import static testcommon.TestConstants.EMPTY_DOCKER_IMAGE
import static config.AppConstants.*

class TestSearch extends AbstractRatPackTest
{
	@ClassRule
	public static DockerContainerResource docker = dockerContainerResourceFor (EMPTY_DOCKER_IMAGE)

	private static final String badPrefix = "badPrefix:Person"

	@Test
	public void shouldYieldBadPrefixError()
	{
		given()
			.config (raXmlConfig())
			.header ("Accept", "application/atom+xml")
		.when()
			.get ("/record/type/${badPrefix}")
		.then()
			.log ().ifStatusCodeMatches (not (400))
			.statusCode (400)
			.contentType (errorXmlContentType)
			.body (not (empty()))
			.body (hasXPath ("/e:errors/e:incorrect-parameter", namespaces))
			.body (hasXPath ("/e:errors/e:incorrect-parameter/e:message", namespaces, equalTo ("Prefix used in a request parameter could not be found")))
			.body (hasXPath ("/e:errors/e:incorrect-parameter/e:parameter-name", namespaces, equalTo ("type")))
			.body (hasXPath ("/e:errors/e:incorrect-parameter/e:parameter-value", namespaces, equalTo (badPrefix)))
	}

	@Test
	public void shouldYieldErrorForBadRecordType()
	{
		given()
			.config (raXmlConfig())
			.header ("Accept", "application/atom+xml")
			.queryParam ('type', badPrefix)
		.when()
			.get ("/record")
		.then()
			.log ().ifStatusCodeMatches (not (400))
			.statusCode (400)
			.contentType (errorXmlContentType)
			.body (not (empty()))
			.body (hasXPath ("/e:errors/e:incorrect-parameter", namespaces))
			.body (hasXPath ("/e:errors/e:incorrect-parameter/e:message", namespaces, equalTo ("Prefix used in a request parameter could not be found")))
			.body (hasXPath ("/e:errors/e:incorrect-parameter/e:parameter-name", namespaces, equalTo ("type")))
			.body (hasXPath ("/e:errors/e:incorrect-parameter/e:parameter-value", namespaces, equalTo (badPrefix)))
	}

	@Test
	public void shouldYieldErrorForBadRecordReferesTo()
	{
		given()
			.config (raXmlConfig())
			.header ("Accept", "application/atom+xml")
			.queryParam ('refers-to', badPrefix)
		.when()
			.get ("/record")
		.then()
			.log ().ifStatusCodeMatches (not (400))
			.statusCode (400)
			.contentType (errorXmlContentType)
			.body (not (empty()))
			.body (hasXPath ("/e:errors/e:incorrect-parameter", namespaces))
			.body (hasXPath ("/e:errors/e:incorrect-parameter/e:message", namespaces, equalTo ("Prefix used in a request parameter could not be found")))
			.body (hasXPath ("/e:errors/e:incorrect-parameter/e:parameter-name", namespaces, equalTo ("refers-to")))
			.body (hasXPath ("/e:errors/e:incorrect-parameter/e:parameter-value", namespaces, equalTo (badPrefix)))
	}

	@Test
	public void shouldYieldErrorForBadRecordReferencedBy()
	{
		given()
			.config (raXmlConfig())
			.header ("Accept", "application/atom+xml")
			.queryParam ('referenced-by', badPrefix)
		.when()
			.get ("/record")
		.then()
			.log ().ifStatusCodeMatches (not (400))
			.statusCode (400)
			.contentType (errorXmlContentType)
			.body (not (empty()))
			.body (hasXPath ("/e:errors/e:incorrect-parameter", namespaces))
			.body (hasXPath ("/e:errors/e:incorrect-parameter/e:message", namespaces, equalTo ("Prefix used in a request parameter could not be found")))
			.body (hasXPath ("/e:errors/e:incorrect-parameter/e:parameter-name", namespaces, equalTo ("referenced-by")))
			.body (hasXPath ("/e:errors/e:incorrect-parameter/e:parameter-value", namespaces, equalTo (badPrefix)))
	}
}

