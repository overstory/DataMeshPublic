package tools

/**
 * Created by marcin on 05/06/2015.
 *
 */
import com.google.inject.Inject
import com.google.inject.name.Named
import groovy.util.logging.Slf4j
import org.json.JSONObject
import org.json.XML

import javax.xml.transform.ErrorListener
import javax.xml.transform.Result
import javax.xml.transform.Templates
import javax.xml.transform.Transformer
import javax.xml.transform.TransformerException
import javax.xml.transform.TransformerFactory
import javax.xml.transform.stream.StreamResult
import javax.xml.transform.stream.StreamSource

@Slf4j
class FormatTransformHelper
{
	@Inject
	@SuppressWarnings ("StaticNonFinalField")
	static TransformerFactory transFactory

	@Inject @Named ("BuildInfoVersion") static String buildVersion
	@Inject @Named ("BuildInfoDate") static String buildDate
	@Inject @Named ("JobsNodeName") static String hostName

	public static String transformXml (String xmlString, String xslName)
	{
		transformXml (new StreamSource (new StringReader (xmlString)), transformerFor (xslName))
	}

	public static String transformXml (StreamSource xmlSource, String xslName)
	{
		transformXml (xmlSource, transformerFor (xslName))
	}

	public static String transformXml (StreamSource xmlSource, StreamSource xslt)
	{
		transformXml (xmlSource, transFactory.newTransformer (xslt))
	}

	public static String transformXml (StreamSource xmlSource, Transformer transformer)
	{
		StringWriter writer = new StringWriter()

		transformXml (xmlSource, transformer, new StreamResult (writer))

		return writer.toString()
	}


	public static void transformXml (String xmlString, String xslName, Result result)
	{
		transformXml (new StreamSource (new StringReader (xmlString)), transformerFor (xslName), result)
	}


	public static void transformXml (StreamSource xmlSource, String xslName, Result result)
	{
		transformXml (xmlSource, transformerFor (xslName), result)
	}

	public static void transformXml (StreamSource xmlSource, StreamSource xslt, Result result)
	{
		transformXml (xmlSource, transFactory.newTransformer (xslt), result)
	}

	public static void transformXml (StreamSource xmlSource, Transformer transformer, Result result)
	{
		try {
			transformer.setParameter ('build-version', buildVersion)
			transformer.setParameter ('build-date', buildDate)
			transformer.setParameter ('hostname', hostName)
			transformer.transform (xmlSource, result)
		} catch (Exception e) {
			log.error ("transformXml: ${e.toString()}", e)
			"<transform-error>${e}</transform-error>"
		}
	}

	// -----------------------------------------------------------------------------

	private static final Map<String,Templates> templatesCache = [:]
	private static boolean errorHandlerSet = false

	private static Transformer transformerFor (String xslName)
	{
		Templates templates = templatesCache [xslName]

		if (templates == null) {
			if ( ! errorHandlerSet) {
				transFactory.setErrorListener (new SuppressNoMatchErrorListener (defaultErrorHandler: transFactory.getErrorListener()))
				errorHandlerSet = true
			}

			templates = transFactory.newTemplates (new StreamSource (this.getClassLoader().getResourceAsStream (xslName)))

			templatesCache [xslName] = templates
		}

		templates.newTransformer()
	}

	// This is a customized ErrorListener to suppress warnings from the auto-generated Schematron XSLT about expressions that will never match anything
	private static class SuppressNoMatchErrorListener implements ErrorListener
	{
		private ErrorListener defaultErrorHandler

		@Override
		public void warning (TransformerException exception) throws TransformerException
		{
			if ( ! exception.message.endsWith ('will never select anything')) {
				if (defaultErrorHandler) defaultErrorHandler.warning (exception)
			}
		}

		@Override
		public void error (TransformerException exception) throws TransformerException
		{
			if (defaultErrorHandler) defaultErrorHandler.error (exception)
		}

		@Override
		public void fatalError (TransformerException exception) throws TransformerException
		{
			if (defaultErrorHandler) defaultErrorHandler.fatalError (exception)
		}
	}

	// -----------------------------------------------------------------------------

	static String xmlToJson (String xmlString)
	{
		JSONObject jsonObject = XML.toJSONObject (xmlString)
		return jsonObject.toString()
	}

	static String jsonToXml (String jsonString)
	{
		JSONObject jsonObject = new JSONObject (jsonString)
		return XML.toString (jsonObject)
	}

	static String invalidXmlCharsPattern  = '[^\u0009\r\n\u0020-\uD7FF\uE000-\uFFFD]'

	// this is to deal with the bad xml coming from the title maintenance service and should be removed in the future
	static String scrubXml (String xmlString)
	{
		return xmlString.replaceAll (invalidXmlCharsPattern, '')
	}
}
