package handlers.rdf

import handlers.MLPassThruHttpClientHandler
import ratpack.handling.Context
import ratpack.handling.Handler


/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 10/7/16
 * Time: 11:34 PM
 */
class RdfHandler implements Handler
{
	@Override
	void handle (Context context) throws Exception
	{
		context.insert (context.get (MLPassThruHttpClientHandler))
	}
}
