package testcommon.docker

import config.AppConfigBuilder
import org.junit.rules.ExternalResource

/**
 * This is a JUnit ExternalResource @ClassRule implementation that holds a handle to a Docker container.  The before()
 * method is called before running any of the tests, and after() is called after the last one is finished.
 * An instance of this class is constructed and stored in a static class variable.  It persists across all instances
 * of the test class as each test is run.
 * User: ron
 * Date: 6/7/15
 * Time: 8:48 PM
 */
class DockerContainerResource extends ExternalResource
{
	private final DockerMarkLogic dockerContainer

	static {
		AppConfigBuilder.loadLogback()
	}

	DockerContainerResource (DockerMarkLogic dockerMarkLogic)
	{
		dockerContainer = dockerMarkLogic
	}

//	DockerContainerResource (String imageName)
//	{
//		dockerContainer = initDockerMarkLogic (imageName, -1, null)
//	}
//
//	DockerContainerResource (String imageName, int testPort, String volume)
//	{
//		dockerContainer = initDockerMarkLogic (imageName, testPort, volume)
//	}
//
//	private static DockerMarkLogic initDockerMarkLogic (String imageName, int port, String volume)
//	{
//		ConfigObject config = AppConfigBuilder.appConfig()
//
//		new DockerMarkLogic (
//			user: config.docker.mluser,
//			password: config.docker.mlpassword,
//			testPort: (port == -1) ? config.xmlreposervice.port : port,
//			volume: (volume == null) ? config.docker.appserverRoot : volume,
//			hostName: config.docker.dockerHostName,
//			image: imageName,
//			certDirectory: config.docker.dockerCertDir,
//			dockerUser: config.docker.dockerUsername,
//			dockerPassword: config.docker.dockerPassword,
//			dockerEmail: config.docker.dockerEmail)
//	}

	@Override
	protected void before() throws Throwable
	{
		super.before()

		dockerContainer.setup()
	}

	@Override
	protected void after()
	{
		super.after()

		dockerContainer.tearDown()
	}
}
