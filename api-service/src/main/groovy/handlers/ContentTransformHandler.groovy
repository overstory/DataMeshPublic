package handlers

import ratpack.handling.Context
import ratpack.handling.Handler

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 9/24/16
 * Time: 3:40 AM
 */
class ContentTransformHandler implements Handler
{
	private final SimpleHttpResponse myResponse

	ContentTransformHandler (SimpleHttpResponse myResponse)
	{
		this.myResponse = myResponse
	}

	@Override
	void handle (Context context) throws Exception
	{
		myResponse.headers.each { String name, String value ->
			context.response.headers.add (name, value)
		}

		context.response.status (myResponse.statusCode)
		context.response.contentType (myResponse.contentType)
		context.response.send (myResponse.body.bytes)
	}
}
