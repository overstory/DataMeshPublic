package integration.api

import org.junit.Before
import org.junit.ClassRule
import org.junit.Test
import testcommon.AbstractRatPackTest
import testcommon.docker.DockerContainerResource
import static testcommon.TestConstants.*

import static com.jayway.restassured.RestAssured.*
import static config.AppConstants.*
import static org.hamcrest.Matchers.*

class TestApi extends AbstractRatPackTest
{
	@ClassRule
	public static DockerContainerResource docker = dockerContainerResourceFor (EMPTY_DOCKER_IMAGE)

	@Before
	public void setup()
	{
		insurePrefix ('ost', 'http://rdf.overstory.co.uk/rdf/terms/')
		loadTestRecordByUri ('urn:overstory.co.uk:id:api:bootstrap')
	}

	@Test
	public void shouldReturnApiInfo()
	{
		given()
			.config (raXmlConfig())
			.header ("Accept", "application/vnd.overstory.record+xml")
		.when()
			.get ("/api")
		.then()
			.log().ifStatusCodeMatches (not(OK))
			.statusCode (OK)
			.contentType ("application/vnd.overstory.record+xml")
			.body (not (empty()))
			.body (hasXPath ('/osc:api/osc:uri', namespaces, equalTo ('urn:overstory.co.uk:id:api:bootstrap')))
			.body (hasXPath ('count(/osc:api/osc:link)', namespaces, equalTo ('4')))
	}
}
