package handlers

import ratpack.handling.Context
import ratpack.handling.Handler

import java.nio.file.Path


/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 10/7/16
 * Time: 11:34 PM
 */
class NotFoundHandler implements Handler
{
	@Override
	void handle (Context context) throws Exception
	{
//		context.insert (context.get (MLPassThruHttpClientHandler))

		Path asset = context.file ("public/404.html")

		if (asset.toFile().exists()) {
			context.response.status (404)
			context.response.contentType ('text/html')
			context.response.send (asset.text)
		} else {
			context.response.contentType ('text/plain')
			context.response.send ('Oh dear, I don\'t seem to have one of those\n')
		}
	}
}
