package handlers.record

import com.google.inject.Inject
import handlers.MLPassThruHttpClientHandler
import ratpack.handling.Context
import ratpack.handling.Handler
import repositories.XmlRepository

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 9/30/16
 * Time: 9:31 PM
 */
class RecordListHandler implements Handler
{
	private final XmlRepository xmlRepository

	@Inject
	RecordListHandler (XmlRepository xmlRepository)
	{
		this.xmlRepository = xmlRepository
	}

	@Override
	void handle (Context context) throws Exception
	{
		context.byMethod {
			context.insert (context.get (MLPassThruHttpClientHandler))
		}
	}
}
