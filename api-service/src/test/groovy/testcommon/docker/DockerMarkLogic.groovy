package testcommon.docker

import com.github.dockerjava.api.DockerClient
import com.github.dockerjava.api.command.CreateContainerResponse
import com.github.dockerjava.api.model.*
import com.github.dockerjava.core.DefaultDockerClientConfig
import com.github.dockerjava.core.DockerClientBuilder
import com.github.dockerjava.core.DockerClientConfig
import groovy.util.logging.Slf4j
import groovyx.net.http.HTTPBuilder
import org.slf4j.Logger
import org.slf4j.LoggerFactory
/**
 * Created by IntelliJ IDEA.
 * User: craig
 * Date: 15-01-30
 * Time: 9:22 PM
 */
@Slf4j
public class DockerMarkLogic
{
	private DockerClient dockerClient
	private CreateContainerResponse container
	private boolean started
	private boolean created

	String hostname
	URI hostUri
	String volume
	String image
	String certDirectory
	String dockerUser
	String dockerPassword
	String dockerEmail
	int testPort
	String user
	String password

	void setHostName (String hostname)
	{
		this.hostname = hostname
		this.hostUri = new URI ("tcp://${hostname}:2376")
	}

	void setup()
	{
		DockerClientConfig config = DefaultDockerClientConfig.createDefaultConfigBuilder()
			.withDockerHost (hostUri.toString())
			.withRegistryUsername (dockerUser)
			.withRegistryPassword (dockerPassword)
			.withRegistryEmail (dockerEmail)
			.withRegistryUrl ("https://index.docker.io/v1/")
			.withDockerTlsVerify ("1")
			.withDockerCertPath (certDirectory).build()
		dockerClient = DockerClientBuilder.getInstance (config).build()

		// Port the Content Service listens on
		ExposedPort tcpData = ExposedPort.tcp (5000)
		ExposedPort tcpQC = ExposedPort.tcp (8000)
		ExposedPort tcpAdminUI = ExposedPort.tcp (8001)

		// Logical path where MarkLogic in the container is configured to point to
		Volume containerVolume = new Volume ('/opt/appserver-root')

		try
		{
			boolean needPull = true;

			dockerClient.listImagesCmd().exec().each { Image img ->
				img.repoTags.each { String tag ->
					if (image.equals (tag)) needPull = false
				}
			}

			if (needPull) {
				log.error ("Missing Docker image: ${image}, please run 'docker pull ${image}'")

				// Can't seem to get an automated pull to work anymore.  Complains that image 'overstory/cup-dev' can't be found.

//				log.info("Pulling Docker image: '${image}' ... ")
//				System.out.flush()
//
//				PullImageResultCallback prcb = new PullImageResultCallback()
//				dockerClient.pullImageCmd (image).exec (prcb)
//				prcb.awaitSuccess()
//
//				log.info("Done")
			}

			// External port (where the outside world can connect) passed in on the constructor
			Ports.Binding bindingTestPort = Ports.Binding.bindPort (testPort)
			Ports.Binding bindingTestPortPlus1 = Ports.Binding.bindPort (testPort + 1)
			Ports.Binding bindingTestPortPlus2 = Ports.Binding.bindPort (testPort + 2)
			Ports portBindings = new Ports()
			// Bind the inside port to the outside port
			portBindings.bind (tcpData, bindingTestPort)
			portBindings.bind (tcpQC, bindingTestPortPlus1)
			portBindings.bind (tcpAdminUI, bindingTestPortPlus2)

			container = dockerClient.createContainerCmd (image)
				.withExposedPorts (tcpData, tcpQC)
				.withPortBindings (portBindings)
				.withVolumes (containerVolume)
				.withBinds (new Bind (volume, containerVolume))
				.exec()

			created = true
		}
		catch (Exception e)
		{
			log.error ("Docker Create Container exception: ${e}")
			tearDown()
			throw e
		}

		try
		{
			dockerClient.startContainerCmd (container.id).exec()

			// Note: This presumes an endpoint '/health' that is safe to ping at container startup.  If not, use the three second sleep
			// This is pinging MarkLogic inside the container, which require a bit of time to startup and be listening after the container is up
			// Thread.sleep (3000)
			String userString = (user) ? "${user}:${password}@".toString() : ''
			HTTPBuilder builder = new HTTPBuilder ("http://${userString}${hostname}:${testPort}/health".toString())

			for (int i = 0; i < 30; i++) {
				try {
					builder.get ([:])
					log.debug ("Container '${container.id}' is ready to go")

					started = true
					break
				} catch (Exception e) {
					log.debug ("Try ${i}: Container ping fail, not ready yet, sleeping (${e})")
					Thread.sleep (100)
				}
			}

			if ( ! started) {
				try {
					dockerClient.killContainerCmd (container.id).exec()
					dockerClient.waitContainerCmd (container.id).exec (null)
				} catch (Exception e) {
					// Nothing
				}

				throw new IllegalStateException ("DockerMarkLogic: container '${container.id}' failed to start in a reasonable time")
			}
		}
		catch (Exception e)
		{
			log.error ("Docker Start Container exception: ${e}")

			tearDown()
			throw e
		}
	}

	void tearDown ()
	{
		if (started) {
			dockerClient.killContainerCmd (container.id).exec()
			dockerClient.waitContainerCmd (container.id).exec (null)
		}

		if (created) dockerClient.removeContainerCmd (container.id).exec()
	}
}
