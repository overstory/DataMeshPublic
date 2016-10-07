package config

import com.google.inject.AbstractModule
import net.sf.saxon.TransformerFactoryImpl
import net.sf.saxon.xpath.XPathFactoryImpl
import tools.FormatTransformHelper

import javax.xml.namespace.NamespaceContext
import javax.xml.transform.TransformerFactory
import javax.xml.xpath.XPathFactory

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 5/26/15
 * Time: 4:37 PM
 */
class XmlProcessingConfig extends AbstractModule
{
	@Override
	protected void configure()
	{
		// This explicitly instantiates the Saxon XSLT 2.0 and XPath 2.0 libraries (Saxon-HE)
		bind (TransformerFactory).toInstance (new TransformerFactoryImpl());
		bind (XPathFactory).toInstance (new XPathFactoryImpl());
		bind (NamespaceContext).toInstance (new NameSpacesConfig());

		requestStaticInjection (FormatTransformHelper);
	}
}
