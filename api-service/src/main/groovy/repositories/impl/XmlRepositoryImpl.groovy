package repositories.impl

import com.google.inject.Inject
import com.google.inject.name.Named
import config.AppConstants
import config.RemoteServerProperties
import handlers.SimpleHttpResponse
import ratpack.exec.Promise
import ratpack.http.client.HttpClient
import repositories.XmlRepository

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 9/24/16
 * Time: 3:35 AM
 */
class XmlRepositoryImpl implements XmlRepository
{
	private final RemoteServerProperties repoProps
	private final HttpClient httpClient

	@Inject
	XmlRepositoryImpl (HttpClient httpClient, @Named('XmlRepoConfig') RemoteServerProperties repoProps)
	{
		this.repoProps = repoProps
		this.httpClient = httpClient
	}


	@Override
	Promise<SimpleHttpResponse> getReport (String reportName)
	{
		URI uri = repoProps.uriFor ("report/${reportName}")

		httpClient.get (uri) {
			it.readTimeoutSeconds (repoProps.readTimeout)
			it.headers.set("Accept", AppConstants.applicationAtomXml)
		} map { response ->
			new SimpleHttpResponse (response)
		}
	}
}
