package config

import groovy.util.logging.Slf4j

/**
 * This is a simple property object created and populated automatically from a properties file
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 6/8/15
 * Time: 6:40 PM
 */
@Slf4j
class RemoteServerProperties
{
	String hostname
	int port
	String user
	String password
	String email
	String path = ''
	String patchVerb = 'PATCH'
	int readTimeout = 60
	boolean enable

	@Override
	String toString()
	{
		return "MLServiceApi: hostname=${baseUri}, user=${user}, password=${password}"
	}

	URI getBaseUri()
	{
		return new URI(baseUriString())
	}

	URI uriFor(String path)
	{
		return new URI("${baseUriString()}${path}")
	}

	URI uriFor(String path, String queryString)
	{
		return new URI("${baseUriString()}${path}${queryString ? '?' : ''}${queryString ?: ''}")
	}

	URI uriFor (String path, Map<String,String> queryParams)
	{
		if ((queryParams == null) || queryParams.size() == 0) return uriFor (path)

		StringBuilder sb = new StringBuilder()

		queryParams.each { String key, String value ->
			if (sb.length() != 0) {
				sb.append ('&')
			}

			sb.append (key).append ('=').append (value)
		}

		return uriFor (path, sb.toString())
	}

	void setHostname(String hostname)
	{
		if (hostname.startsWith('\'') && hostname.endsWith('\''))
			this.hostname = hostname.substring(1, hostname.size() - 1)
		else
			this.hostname = hostname
	}

	// ---------------------------------------------------------------

	private String baseUriString()
	{
		"http://${hostname}:${port}/${path}".toString()
	}
}
