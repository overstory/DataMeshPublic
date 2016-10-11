package integration.html

import org.junit.Before
import org.junit.ClassRule
import org.junit.Test
import testcommon.AbstractRatPackTest
import testcommon.docker.DockerContainerResource

import static com.jayway.restassured.RestAssured.*
import static org.hamcrest.Matchers.*
import static testcommon.TestConstants.EMPTY_DOCKER_IMAGE

class TestHtml extends AbstractRatPackTest
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
	public void shouldReturnCorrectLabels()
	{
		String identifier = "urn:overstory.co.uk:id:person:test_record"

		given()
			.config (raXmlConfig())
			.header("Accept", "text/html")
		.when()
			.get ("/record/id/${identifier}")
		.then()
			.log().ifStatusCodeMatches (not (200))
			.statusCode (200)
			.contentType("text/html")
			.body (not (empty()))
			.body (hasXPath ("/html:html/html:body/html:div[@class='starter-template']/html:div[@class='container readable']/html:table/html:tbody/html:tr/html:td[@property='foaf:firstName']/html:p[@class='table-label']", namespaces, startsWith("First")))
			.body (hasXPath ("/html:html/html:body/html:div[@class='starter-template']/html:div[@class='container readable']/html:table/html:tbody/html:tr/html:td[@property='foaf:surname']/html:p[@class='table-label']", namespaces, startsWith("Last")))
			.body (hasXPath ("/html:html/html:body/html:div[@class='starter-template']/html:div[@class='container readable']/html:table/html:tbody/html:tr/html:td[@property='foaf:mbox']/html:p[@class='table-label'][contains(.,'E-mail')]", namespaces))
			.body (hasXPath ("/html:html/html:body/html:div[@class='starter-template']/html:div[@class='container readable']/html:table/html:tbody/html:tr/html:td[@property='foaf:mbox']/html:p[@class='table-label']/html:i[contains(@class, 'fa')]", namespaces))
	}

	@Test
	public void shouldReturnCorrectSubjectAndObject()
	{
		String identifier = "urn:overstory.co.uk:id:person:test_record"

		given()
			.config (raXmlConfig())
			.header("Accept", "text/html")
		.when()
			.get ("/record/id/${identifier}")
		.then()
			.log ().ifStatusCodeMatches (not (200))
			.statusCode (200)
			.contentType("text/html")
			.body (not (empty()))
			.body (hasXPath ("/html:html/html:body/html:div[@class='starter-template']/html:div[@class='container readable']/html:table/html:tbody/html:tr/html:td[@object='rachockim@gmail.com']", namespaces))
			.body (hasXPath ("/html:html/html:body/html:div[@class='starter-template']/html:div[@class='container readable']/html:table/html:tbody/html:tr/html:td[@class='subject-uri']", namespaces, equalTo (identifier)))
	}
}

