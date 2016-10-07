package config

import javax.xml.namespace.NamespaceContext

/**
 * Created by IntelliJ IDEA.
 * User: ron
 * Date: 5/26/15
 * Time: 4:45 PM
 */
class NameSpacesConfig implements NamespaceContext
{
	static final Map<String, String> namespaceMap = [
		"e"   : "http://ns.overstory.co.uk/namespaces/resources/error",
		"oss" : "http://ns.overstory.co.uk/namespaces/search",
		"atom": "http://www.w3.org/2005/Atom"
	]

	@Override
	String getNamespaceURI(String prefix) {
		return namespaceMap.get(prefix)
	}

	@Override
	String getPrefix(String namespaceURI) {
		for (Map.Entry entry : namespaceMap.entrySet()) {
			if (entry.value.equals(namespaceURI)) return entry.key
		}

		return null
	}

	@Override
	Iterator getPrefixes(String namespaceURI) {
		return namespaceMap.keySet().iterator()
	}
}
