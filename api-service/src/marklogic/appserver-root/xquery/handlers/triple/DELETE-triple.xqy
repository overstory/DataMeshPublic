xquery version '1.0-ml';

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "../lib/constants.xqy";
import module namespace r="urn:overstory:modules:data-mesh:handlers:lib:records" at "../lib/lib-records.xqy";

declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";
declare namespace e = "http://ns.overstory.co.uk/namespaces/error";

declare option xdmp:output "indent=yes";

declare variable $subject as xs:string? := xdmp:get-request-field ("subject", ());
declare variable $predicate as xs:string? := xdmp:get-request-field ("predicate", ());
declare variable $object as xs:string? := xdmp:get-request-field ("object", ());

let $validate-incoming-params := r:validate-triple-params ($subject, $predicate, $object)
return
	if (fn:empty ($validate-incoming-params))
	then 
		if ( r:triple-exists ($subject, $predicate, $object)) 
		then (r:delete-triple ($subject, $predicate, $object), xdmp:set-response-code (204, "No Content"))
		else (xdmp:set-response-code (204, "No Content"))
else (
	$validate-incoming-params,
	xdmp:set-response-code (400, "Bad Request"),
	xdmp:set-response-content-type ($const:CT-ERROR-XML)
)