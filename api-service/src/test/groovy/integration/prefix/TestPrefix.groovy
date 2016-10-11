package integration.prefix

import org.junit.Before
import org.junit.ClassRule
import org.junit.Test
import testcommon.AbstractRatPackTest
import testcommon.docker.DockerContainerResource
import static config.AppConstants.*
import static com.jayway.restassured.RestAssured.given

import static testcommon.TestConstants.EMPTY_DOCKER_IMAGE
import static org.hamcrest.Matchers.*

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 10/9/16
 * Time: 11:02 PM
 */
class TestPrefix extends AbstractRatPackTest
{
	@ClassRule
	public static DockerContainerResource docker = dockerContainerResourceFor (EMPTY_DOCKER_IMAGE)

	@Before
	public void setup()
	{
		insurePrefix ('ost', 'http://rdf.overstory.co.uk/rdf/terms/')
		insureTestRecordByUri ('urn:overstory.co.uk:id:prefix:testprefix')
	}

	@Test
	public void shouldDeletePrefixExists()
	{
		insureTestRecordByUri ('urn:overstory.co.uk:id:prefix:testprefix')

		String prefixName = "testprefix"
		String etag = getEtagForUri ("/rdf/prefix/${prefixName}")

		assert etag

		given()
			.config (raXmlConfig())
			.header ("ETag", etag)
		.when()
			.delete ("/rdf/prefix/${prefixName}")
		.then()
			.log ().ifStatusCodeMatches (not (204))
			.statusCode (204)
			.body (equalTo(""))
	}

	@Test
	public void shouldDeletePrefixExistsBadEtag()
	{
		String prefixName = "testprefix"
		String prefixUri = "http://test.com/"

		insurePrefix (prefixName, prefixUri)
		insureTestRecordByUri ('urn:overstory.co.uk:id:prefix:testprefix')
		String badEtag = "bad-etag-value"

		given()
			.config (raXmlConfig())
			.header ("ETag", badEtag)
		.when()
			.delete ("/rdf/prefix/${prefixName}")
		.then()
			.log ().ifStatusCodeMatches (not (Conflict))
			.statusCode (Conflict)
			.contentType (errorXmlContentType)
			.body (not (empty()))
			.body (hasXPath ('/e:errors/e:etag-mismatch', namespaces))
			.body (hasXPath ("/e:errors/e:etag-mismatch/e:message", namespaces, equalTo ("Given ETag value does not match current resource ETag")))
			.body (hasXPath ("/e:errors/e:etag-mismatch/e:given-etag", namespaces, equalTo (badEtag)))
			.body (hasXPath ("/e:errors/e:etag-mismatch/e:current-etag", namespaces))

	}

	@Test
	public void shouldDeletePrefixNotExists()
	{
		String prefixName = "bogustestprefix"

		given()
			.config (raXmlConfig())
		.when()
			.delete ("/rdf/prefix/${prefixName}")
		.then()
			.log ().ifStatusCodeMatches (not (204))
			.statusCode (204)
			.body (isEmptyOrNullString())
	}

	@Test
	public void shouldGetPrefixExists()
	{
		String prefixName = "testprefix"
		String prefixIdentifier = "urn:overstory.co.uk:id:prefix:${prefixName}"

		insurePrefix (prefixName, prefixIdentifier)

		given()
			.config (raXmlConfig())
			.header ("Accept", applicationDataMeshRecordXml)
		.when()
			.get ("/rdf/prefix/${prefixName}")
		.then()
			.log ().ifStatusCodeMatches (not (OK))
			.statusCode (OK)
			.contentType (applicationDataMeshRecordXml)
			.body (not (empty()))
			.body (hasXPath ('/osc:prefix', namespaces))
			.body (hasXPath ("/osc:prefix/osc:uri", namespaces, equalTo (prefixIdentifier)))
			.body (hasXPath ("/osc:prefix/@about", namespaces, equalTo (prefixIdentifier)))
			.header ("ETag", not (empty()))
	}

	@Test
	public void shouldGetPrefixNotExists()
	{
		String prefixName = "bogustestprefix"
		String prefixIdentifier = "urn:overstory.co.uk:id:prefix:${prefixName}"

		given()
			.config (raXmlConfig())
			.header ("Accept", applicationDataMeshRecordXml)
		.when()
			.get ("/rdf/prefix/${prefixName}")
		.then()
			.log ().ifStatusCodeMatches (not (NotFound))
			.statusCode (NotFound)
			.contentType (errorXmlContentType)
			.body (not (empty()))
			.body (hasXPath ('/e:errors/e:not-found', namespaces))
			.body (hasXPath ("/e:errors/e:not-found/e:message", namespaces, equalTo ("Prefix not found")))
			.body (hasXPath ("/e:errors/e:not-found/e:prefix-name", namespaces, equalTo (prefixName)))
			.body (hasXPath ("/e:errors/e:not-found/e:uri", namespaces, equalTo (prefixIdentifier)))
	}

	@Test
	public void shouldPutPrefixExists ()
	{
		String prefixName = "testprefix"
		String prefixUri = "http://test.com/"

		insurePrefix (prefixName, prefixUri)

		String etag = getEtagForUri ("/rdf/prefix/${prefixName}")

		given()
			.config (raXmlConfig())
			.header ("ETag", etag)
			.body (prefixUri)
		.when()
			.put ("/rdf/prefix/${prefixName}")
		.then()
			.log ().ifStatusCodeMatches (not (201))
			.statusCode (201)
			.body (isEmptyOrNullString())
	}

	@Test
	public void shouldPutPrefixExistsBadEtag()
	{
		String prefixName = "testprefix"
		String prefixUri = "http://test.com/"

		insurePrefix (prefixName, prefixUri)

		String badEtag = "bad-etag-value"

		given()
			.config (raXmlConfig())
			.header ("ETag", badEtag)
			.body (prefixUri)
		.when()
			.put ("/rdf/prefix/${prefixName}")
		.then()
			.log ().ifStatusCodeMatches (not (Conflict))
			.statusCode (Conflict)
			.body (not (empty()))
			.body (hasXPath ('/e:errors/e:etag-mismatch', namespaces))
			.body (hasXPath ("/e:errors/e:etag-mismatch/e:message", namespaces, equalTo ("Given ETag value does not match current resource ETag")))
			.body (hasXPath ("/e:errors/e:etag-mismatch/e:given-etag", namespaces, equalTo (badEtag)))
			.body (hasXPath ("/e:errors/e:etag-mismatch/e:current-etag", namespaces))
	}

	@Test
	public void shouldPutPrefixNotExists()
	{
		String prefixName = "testprefixxxx"
		String prefixUri = "http://test.com/"

		given()
			.config (raXmlConfig())
			.body (prefixUri)
		.when()
			.put ("/rdf/prefix/${prefixName}")
		.then()
			.log ().ifStatusCodeMatches (not (Created))
			.statusCode (Created)
			.body (isEmptyOrNullString())
	}

	@Test
	public void shouldPutPrefixNotExistsBadUri ()
	{
		String prefixName = "testprefix"
		String prefixUri = "bad-prefix-uri"

		given()
			.config (raXmlConfig())
			.body (prefixUri)
		.when()
			.put ("/rdf/prefix/${prefixName}")
		.then()
			.log ().ifStatusCodeMatches (not (BadRequest))
			.statusCode (BadRequest)
			.body (not (empty()))
			.body (hasXPath ('/e:errors/e:malformed-body', namespaces))
			.body (hasXPath ("/e:errors/e:malformed-body/e:message", namespaces, equalTo ("Prefix uri is incorrect")))
			.body (hasXPath ("/e:errors/e:malformed-body/e:prefix-uri", namespaces, equalTo (prefixUri)))

	}
}
