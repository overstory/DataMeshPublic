xquery version '1.0-ml';

module namespace semantic="urn:overstory:modules:data-mesh:handlers:lib:semantic";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "constants.xqy";
import module namespace rdfa="http://marklogic.com/ns/rdfa-impl#" at "rdfa.xqy";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare variable $uri-qname := fn:QName ($const:DATA-MESH-ELEMENT-NAMESPACE-URI, "dm:uri");

declare function inject-sem-triples (
	$record as element(),
	$full-resource-uri as xs:string
) as element()
{
	element { fn:node-name ($record) } {
		namespace { "dm" } { $const:DATA-MESH-ELEMENT-NAMESPACE-URI }, $record/namespace::*,
		$record/@*, if ($record/@about) then () else attribute about { $full-resource-uri },
		element { $uri-qname } { $full-resource-uri },
		$record/*[fn:node-name(.) ne $uri-qname],
		extract-triples ($record)
		, rdfa:parse_rdfa ($record, $const:DATA-MESH-URI-SPACE-ROOT)   (: DELETE ME :)
	}
};

declare function extract-triples (
	$record as element()
) as element(sem:triples)
{
	<sem:triples>{
		sem:rdf-parse (rdfa:parse_rdfa ($record, $const:DATA-MESH-URI-SPACE-ROOT)),
		sem:rdf-parse ($record/descendant-or-self::rdf:RDF/rdf:Description)
	}</sem:triples>
};

