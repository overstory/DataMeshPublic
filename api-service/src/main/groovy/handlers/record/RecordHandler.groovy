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
class RecordHandler implements Handler
{
	private final XmlRepository xmlRepository
	private final Handler getHandler = new GetRecordHandler ()
	private final Handler putHandler = new PutRecordHandler ()

	@Inject
	RecordHandler (XmlRepository xmlRepository)
	{
		this.xmlRepository = xmlRepository
	}

	@Override
	void handle (Context context) throws Exception
	{
		context.byMethod {
			it.get { context.insert (getHandler) }
			it.put { context.insert (putHandler) }
		}
	}

	private class GetRecordHandler implements Handler
	{
		@Override
		void handle (Context context) throws Exception
		{
			context.insert (context.get (MLPassThruHttpClientHandler))
		}
	}

	private class PutRecordHandler implements Handler
	{
		@Override
		void handle (Context context) throws Exception
		{
			context.insert (context.get (MLPassThruHttpClientHandler))
		}
	}
}
