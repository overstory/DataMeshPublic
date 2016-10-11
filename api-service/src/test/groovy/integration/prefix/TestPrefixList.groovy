package integration.prefix

import org.junit.Before
import org.junit.ClassRule
import org.junit.Test
import testcommon.AbstractRatPackTest
import testcommon.docker.DockerContainerResource

import static com.jayway.restassured.RestAssured.given
import static config.AppConstants.*
import static org.hamcrest.Matchers.*
import static testcommon.TestConstants.EMPTY_DOCKER_IMAGE

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 10/9/16
 * Time: 11:02 PM
 */
class TestPrefixList extends AbstractRatPackTest
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
	public void shouldGetPrefixListSimple()
	{
		given()
			.config (raXmlConfig())
			.header ("Accept", applicationXml)
			.log().all()
		.when()
			.get ("/rdf/prefix")
		.then()
			.log ().ifStatusCodeMatches (not (200))
			.statusCode (200)
			.contentType (applicationXml)
			.body (not (empty()))
			.body (hasXPath ('/oss:result/@first', namespaces, equalTo ('1')))
			.body (hasXPath ('/oss:result/@last', namespaces, equalTo ('2')))
			.body (hasXPath ('/oss:result/@total-hits', namespaces, equalTo ('2')))
			.body (hasXPath ('/oss:result/@request-url', namespaces, equalTo ('/rdf/prefix')))
			.body (hasXPath ('/oss:result/oss:search-criteria', namespaces))
			.body (hasXPath ('/oss:result[oss:uri = "urn:overstory.co.uk:id:prefix:ost"]', namespaces))
			.body (hasXPath ('/oss:result[oss:uri = "urn:overstory.co.uk:id:prefix:testprefix"]', namespaces))
	}

	@Test
	public void shouldGetPrefixListAtom()
	{
		given()
			.config (raXmlConfig())
			.header ("Accept", applicationAtomXml)
			.log().all()
		.when()
			.get ("/rdf/prefix")
		.then()
			.log ().ifStatusCodeMatches (not (200))
			.statusCode (200)
			.contentType (applicationAtomXml)
			.body (not (empty()))
			.body (hasXPath ('/atom:feed', namespaces))
			.body (hasXPath ("/atom:feed/atom:id", namespaces, equalTo ("/rdf/prefix")))
			.body (hasXPath ('/atom:feed/atom:link[@rel = "self"]/@type', namespaces, equalTo (applicationAtomXml)))
			.body (hasXPath ('/atom:feed/oss:search-criteria', namespaces))
//			.body (hasXPath ('/atom:feed/oss:pagination', namespaces))
			.body (hasXPath ('count(/atom:feed/atom:entry)', namespaces, equalTo ("2")))
			.body (hasXPath ('/atom:feed/atom:entry[atom:id = "urn:overstory.co.uk:id:prefix:ost"]', namespaces))
			.body (hasXPath ('/atom:feed/atom:entry[atom:id = "urn:overstory.co.uk:id:prefix:testprefix"]', namespaces))
			.body (hasXPath ('/atom:feed/atom:entry[1]/atom:content/@type', namespaces, equalTo (applicationDataMeshRecordXml)))
	}
}
