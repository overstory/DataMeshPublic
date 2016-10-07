package handlers

import com.google.inject.Inject
import com.google.inject.name.Named
import config.RemoteServerProperties
import groovy.util.logging.Slf4j
import ratpack.handling.Context
import ratpack.handling.Handler
import ratpack.http.Headers
import ratpack.http.TypedData
import ratpack.http.client.HttpClient
import ratpack.http.client.ReceivedResponse

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 5/20/15
 * Time: 2:24 PM
 */
@Slf4j
class MLPassThruHttpClientHandler implements Handler
{
	private static final List<String> PASSTHRU_REQUEST_HEADERS = ['etag', 'content-type', 'content-length', 'if-match', 'if-none-match', 'if-modified-since']
	private static final Map<String, String> ACCEPT_HEADER_MAP =
		["application/vnd.cup.content.bundle.contents.expanded.v1+json":"application/vnd.cup.content.bundle.contents.expanded.v1+xml",
		 "application/vnd.cup.content.bundle.contents.v1+json":"application/vnd.cup.content.bundle.contents.v1+xml",
		 "application/vnd.cup.binary-references.content.feed+json":"application/vnd.cup.binary-references.content.feed+xml"]
	private static final List<String> PASSTHRU_RESPONSE_HEADERS = ['Content-type', 'Content-Length', 'ETag', 'Last-Modified', 'Location', 'Allow']
	private static final String prefixToRemove = 'datamesh/'

	private final RemoteServerProperties mlapi

	@Inject
	MLPassThruHttpClientHandler (@Named("XmlRepoConfig") RemoteServerProperties mlapi)
	{
		this.mlapi = mlapi

		log.debug "Instantiated MLPassThruHttpClientHandler"
	}

	@Override
	void handle (Context context)
	{
		context.request.body.then { TypedData body ->
			handlePassthru (context, body)
		}
	}

	void handlePassthru (Context context, TypedData requestBody)
	{
		HttpClient httpClient = context.get (HttpClient)
		String verb = (context.request.method.isPatch() && mlapi.patchVerb) ? (mlapi.patchVerb) : context.request.method.name
		String path = context.request.path ?: ""
		String query = context.request.query ?: ""
		URI uri = mlapi.uriFor (path - prefixToRemove, query)
		Headers headers = context.request.headers
		int readTimeout = mlapi.readTimeout
		long startTime = System.currentTimeMillis()

//println "In handler: verb=${verb}, path=${path} ml-path=${mlapi.uriFor(path,query).toString()}"

		httpClient.request (uri) {
			it.readTimeoutSeconds(readTimeout)
			it.method (verb)
			if (requestBody.buffer.readable || ( ! ['PUT', 'POST', 'PATCH'].contains (verb))) {
				it.body.buffer (requestBody.buffer)
			} else {
				it.body.text (' ')
			}
			it.headers {
				headers.names.each { String hdr ->
					String headerName = hdr.toLowerCase()

					if ((headerName.toLowerCase().startsWith ("x-")) || PASSTHRU_REQUEST_HEADERS.contains (headerName)) {
						String value = headers.get (headerName)

						// FixMe: generalize this
						if (verb.equals ('DELETE') && headerName.equals ("content-length")) value = null

						if (headerName.equals ("content-type")) {
							String [] parts = value.split (';')

							if ((parts.length == 1) || (! parts[1].trim().startsWith ('charset'))) {
								// This is to prevent RatPack appending an incorrect charset to the Content-Type, REST Assured still needs to set an explicit charset=UTF-8 when testing
								value = "${value}; charset=UTF-8"
							}
						}

						if (value) it.set (headerName, value)
					}
				}

				def acceptHeader = context.request.headers.get("Accept")

				if (acceptHeader) {
					if (ACCEPT_HEADER_MAP.get (acceptHeader)) {
						it.set ("Accept", ACCEPT_HEADER_MAP.get (acceptHeader))
					}
					else {
						it.set ("Accept", acceptHeader)
					}
				}

				// Hackery to work around AWS ELB inability to handle PATCH verb
				if (context.request.method.isPatch() && mlapi.patchVerb) {
					it.set ("x-method-override", "PATCH")
				}
			}
		} onError { Throwable exception ->
			log.error ("Error from MarkLogic for ${verb} ${uri} (elapsed: ${System.currentTimeMillis() - startTime}): ${exception}")

			if (exception instanceof Exception) {
				context.render (new SimpleHttpResponse (exception))
			} else {
				throw exception		// punt on runtime exception, for now
			}
		} then { ReceivedResponse response ->
			log.debug ("Call to MarkLogic: ${System.currentTimeMillis() - startTime} milliseconds, ${verb} (${response.statusCode}) ${uri}")

			context.response.status (response.statusCode)

			PASSTHRU_RESPONSE_HEADERS.each {
				if (response.headers.get(it))
					context.response.headers.add (it, response.headers.get(it))
			}

			response.headers.getNames().each {
				if (it.toLowerCase().startsWith ('x-')) {
					context.response.headers.add (it, response.headers.get(it))
				}
			}

			context.render (new SimpleHttpResponse (response))
		}

		// ToDo: On successful response from ML, need to check the Accept: request on the original request and transform if needed.  That should be as generic as possible
	}

}
