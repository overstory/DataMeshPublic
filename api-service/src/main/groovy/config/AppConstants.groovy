package config

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 6/22/15
 * Time: 2:43 AM
 */
class AppConstants
{
	static public final String appPropertyName = 'datamesh'

	static public final String errorXmlContentType = "application/vnd.overstory.rest.errors+xml"
	static public final String errorJsonContentType = "application/vnd.overstory.rest.errors+json"

	static public final String mimeWildCard = "*/*"
	static public final String multipartFormData = "multipart/form-data"
	static public final String textPlain = "text/plain"
	static public final String textCsv = "text/csv"
	static public final String textHtml = "text/html"
	static public final String textXml = "text/xml"
	static public final String imageJpeg = "image/jpeg"
	static public final String imagePng = "image/png"
	static public final String imageGif = "image/gif"
	static public final String applicationHtml = "application/html"
	static public final String applicationXHtml = "application/xhtml+xml"
	static public final String applicationXml = "application/xml"
	static public final String applicationPdf = "application/pdf"
	static public final String applicationJson = "application/json"
	static public final String applicationAtomXml = "application/atom+xml"
	static public final String applicationAtomRawXml = "application/vnd.collections.raw+xml"
	static public final String applicationAtomJson = "application/atom+json"
	static public final String applicationCollectionsXml = "application/vnd.collections+xml"
	static public final String applicationCollectionsJson = "application/vnd.collections+json"
	static public final String applicationOctetStream = "application/octet-stream"
	static public final String applicationZip = "application/zip"
	static public final String applicationDataMeshMetaXml = "application/vnd.overstory.meta.id+xml"
	static public final String applicationDataMeshMetaJson = "application/vnd.overstory.meta.id+json"
	static public final String applicationDataMeshRecordXml = "application/vnd.overstory.record+xml"
	static public final String applicationDataMeshRecordJson = "application/vnd.overstory.record+json"

	//http 1.1. status codes
	static public final int OK = 200
	static public final int Created = 201
	static public final int Accepted = 202
	static public final int NoContent = 204
	static public final int NotModified = 304
	static public final int BadRequest = 400
	static public final int NotFound = 404
	static public final int MethodNotAllowed = 405
	static public final int NotAcceptable = 406
	static public final int Conflict = 409
	static public final int PreconditionFailed = 412
	static public final int UnsupportedMediaType = 415
	static public final int InternalServerError = 500
	static public final int BadGateway = 502

	private AppConstants()
	{
		// cannot be instantiated
	}
}
