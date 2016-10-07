xquery version '1.0-ml';

import module namespace r="urn:overstory:modules:data-mesh:handlers:lib:records" at "../lib/lib-records.xqy";
import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "../lib/constants.xqy";

declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";
declare namespace e = "http://ns.overstory.co.uk/namespaces/error";

declare option xdmp:output "indent=yes";

let $incoming-doc as element() := r:get-xml-body()
let $osc-uri := $incoming-doc/osc:uri/string()
let $about-uri := $incoming-doc/@about/string()
let $bad-request := r:validate-incoming-POST-identifiers ($osc-uri,$about-uri)
return
	if (fn:not (fn:empty ($bad-request)))
	then (
		$bad-request,
		xdmp:set-response-content-type ($const:CT-ERROR-XML),
        xdmp:set-response-code (400, "Bad Request")
	)
    else
        let $extracted-triples := r:extract-triples ($incoming-doc)
        let $build-doc as node() := r:build-document ($incoming-doc, $extracted-triples, ())
        let $collections as xs:string* := r:collections-for-record ($incoming-doc, $extracted-triples, $osc-uri)
        return r:load-record ($build-doc, $osc-uri, $collections)

