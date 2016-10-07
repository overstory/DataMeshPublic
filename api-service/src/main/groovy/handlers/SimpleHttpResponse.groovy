package handlers

import config.AppConstants
import io.netty.buffer.ByteBuf
import ratpack.handling.Context
import ratpack.http.MediaType
import ratpack.http.TypedData
import ratpack.http.client.ReceivedResponse
import ratpack.http.internal.DefaultMediaType
import ratpack.render.Renderable

import java.nio.charset.Charset

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 5/31/15
 * Time: 9:55 PM
 */
class SimpleHttpResponse implements Renderable
{
	final int statusCode
	final String contentType
	final TypedData body
	final boolean binary
	final Map<String,String> headers = [:]
	private static final List<String> textContentTypeRegexs = ['^text/.*', '^application/xml.*', '^application/.*\\+xml.*', '^application/json.*', '^application/.*\\+json.*']

	SimpleHttpResponse (String body, String contentType, int code)
	{
		this.body = new TypedDataString (body: body)
		this.statusCode = code
		this.contentType = contentType
		binary = ctIsBinary (contentType)
	}

	SimpleHttpResponse (ReceivedResponse response)
	{
		statusCode = response.status.code
		contentType = response.headers.get ("content-type")
		binary = ctIsBinary (contentType)
		body = new TypedDataClone (response.body, binary)
	}

	SimpleHttpResponse (Throwable e)
	{
		statusCode = 500
		contentType = AppConstants.errorXmlContentType
		binary = ctIsBinary (contentType)

//		body = new TypedDataString (body: IngestionException.formatException (e))
		body = new TypedDataString (body: e.message)
	}

	SimpleHttpResponse header (String name, String value)
	{
		headers [name] = value

		return this
	}

	@Override
	void render (Context context) throws Exception {
		context.insert (new ContentTransformHandler (this))
	}

	@Override
	String toString() {
		return "SimpleHttpResponse: status=${statusCode}, content type=${contentType}, body=${body.text}"
	}

	boolean isBinary()
	{
		binary
	}

	// ------------------------------------------------

	private static boolean ctIsBinary (String contentType)
	{
		if ( ! contentType) return true

		boolean result = true

		textContentTypeRegexs.each { String regex ->
			if (contentType.matches (regex)) result = false
		}

		result
	}

	// ------------------------------------------------

	private static class TypedDataString implements TypedData
	{
		private String body

		@Override
		MediaType getContentType() { null }

		@Override
		String getText() { body }

		@Override
		String getText (Charset charset) { body }

		@Override
		byte[] getBytes() { body.getBytes() }

		@Override
		ByteBuf getBuffer() { null }

		@Override
		void writeTo (OutputStream outputStream) throws IOException {
			throw new IOException ("Not implemented")
		}

		@Override
		InputStream getInputStream () {
			throw new IOException ("Not implemented")
		}
	}

	private static class TypedDataClone implements TypedData
	{
		private String contentType
		private final String text
		private final byte [] bytes

		TypedDataClone (TypedData origBody, boolean binary)
		{
			contentType = origBody.contentType
			text = (binary) ? null : origBody.text
			bytes = origBody.bytes
		}

		@Override
		MediaType getContentType ()
		{
			DefaultMediaType.get (contentType)	// This is using an internal type, but should never be called anyway
		}

		@Override
		String getText ()
		{
			text
		}

		@Override
		String getText (Charset charset)
		{
			text
		}

		@Override
		byte[] getBytes () {
			bytes
		}

		@Override
		ByteBuf getBuffer () {
			return null
		}

		@Override
		void writeTo (OutputStream outputStream) throws IOException {
			outputStream.write (bytes)
		}

		@Override
		InputStream getInputStream () {
			throw new IOException ("Not implemented")
		}
	}
}
