package integration.type

import org.junit.Before
import org.junit.ClassRule
import org.junit.Test
import testcommon.AbstractRatPackTest
import testcommon.docker.DockerContainerResource

import static com.jayway.restassured.RestAssured.given
import static config.AppConstants.*
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
	public void shouldReturnTypeListSimple()
	{
		given()
			.config (raXmlConfig())
			.header ("Accept", applicationXml)
		.when()
			.get ("/rdf/record/type")
		.then()
			.log ().ifStatusCodeMatches (not (OK))
			.statusCode (OK)
			.contentType (applicationXml)
			.body (not (empty()))
			.body (hasXPath ('/oss:result/@first', namespaces, equalTo ('1')))
			.body (hasXPath ('/oss:result/@last', namespaces, equalTo ('10')))
			.body (hasXPath ('/oss:result/@page-size', namespaces, equalTo ('10')))
			.body (hasXPath ('/oss:result/@total-hits', namespaces, equalTo ('4')))
			.body (hasXPath ('count(/oss:result/osc:type)', namespaces, equalTo ('4')))
			.body (hasXPath ("/oss:result/osc:type[osc:type-uri = 'http://rdf.overstory.co.uk/rdf/terms/DataRecord']", namespaces))
			.body (hasXPath ("/oss:result/osc:type[osc:type-curie = 'ost:DataRecord']", namespaces))
			.body (hasXPath ("/oss:result/osc:type[osc:type-uri = 'http://xmlns.com/foaf/0.1/Person']", namespaces))
			.body (hasXPath ("/oss:result/osc:type[osc:type-curie = 'foaf:Person']", namespaces))
			.body (hasXPath ("/oss:result/osc:type[osc:type-uri = 'http://rdf.overstory.co.uk/rdf/terms/MetaRecord']", namespaces))
			.body (hasXPath ("/oss:result/osc:type[osc:type-curie = 'ost:MetaRecord']", namespaces))
			.body (hasXPath ("/oss:result/osc:type[osc:type-uri = 'http://rdf.overstory.co.uk/rdf/terms/Prefix']", namespaces))
			.body (hasXPath ("/oss:result/osc:type[osc:type-curie = 'ost:Prefix']", namespaces))

	}

	@Test
	public void shouldReturnTypeListAtom()
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
			.body (hasXPath ("/atom:feed/atom:link[@rel = 'self']/@href", namespaces, equalTo ("/rdf/record/type")))
			.body (hasXPath ("/atom:feed/atom:link[@rel = 'self']/@type", namespaces, equalTo (applicationAtomXml)))
//			.body (hasXPath ('/atom:feed/oss:pagination', namespaces))
			.body (hasXPath ('/atom:feed/atom:entry[atom:id = "ost:DataRecord"]/osc:type-uri', namespaces, equalTo ('http://rdf.overstory.co.uk/rdf/terms/DataRecord')))
			.body (hasXPath ('/atom:feed/atom:entry[atom:id = "ost:DataRecord"]/osc:type-curie', namespaces, equalTo ('ost:DataRecord')))
			.body (hasXPath ('/atom:feed/atom:entry[atom:id = "foaf:Person"]/osc:type-uri', namespaces, equalTo ('http://xmlns.com/foaf/0.1/Person')))
			.body (hasXPath ('/atom:feed/atom:entry[atom:id = "foaf:Person"]/osc:type-curie', namespaces, equalTo ('foaf:Person')))
			.body (hasXPath ('/atom:feed/atom:entry[atom:id = "ost:MetaRecord"]/osc:type-uri', namespaces, equalTo ('http://rdf.overstory.co.uk/rdf/terms/MetaRecord')))
			.body (hasXPath ('/atom:feed/atom:entry[atom:id = "ost:MetaRecord"]/osc:type-curie', namespaces, equalTo ('ost:MetaRecord')))
			.body (hasXPath ('/atom:feed/atom:entry[atom:id = "ost:Prefix"]/osc:type-uri', namespaces, equalTo ('http://rdf.overstory.co.uk/rdf/terms/Prefix')))
			.body (hasXPath ('/atom:feed/atom:entry[atom:id = "ost:Prefix"]/osc:type-curie', namespaces, equalTo ('ost:Prefix')))

	}
}
