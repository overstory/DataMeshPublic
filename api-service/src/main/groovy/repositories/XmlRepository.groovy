package repositories

import handlers.SimpleHttpResponse
import ratpack.exec.Promise

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 6/1/15
 * Time: 7:26 PM
 */
interface XmlRepository
{
	Promise<SimpleHttpResponse> getReport (String reportName)
}
