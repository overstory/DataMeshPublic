xquery version '1.0-ml';

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "../lib/constants.xqy";
import module namespace r="urn:overstory:modules:data-mesh:handlers:lib:records" at "../lib/lib-records.xqy";

declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";
declare namespace e = "http://ns.overstory.co.uk/namespaces/error";

declare option xdmp:output "indent=yes";

declare variable $prefix := xdmp:get-request-field ("prefix", ());
declare variable $prefix-identifier := r:build-prefix-uri($prefix);
declare variable $incoming-etag as xs:string? := xdmp:get-request-header ("ETag", "");

if ( r:prefix-exists ($prefix-identifier)) 
then (
	let $record-etag as xs:string? := r:etag-from-record-uri ($prefix-identifier)
	let $validate-etag := r:validate-incoming-etag ($incoming-etag, $record-etag)
	return
		if ($validate-etag)
		then (
			r:delete-prefix ($prefix-identifier),
    		xdmp:set-response-code (204, "No Content")
		)
		else (
			<e:errors>
	            <e:etag-mismatch>
	                <e:message>Given ETag value does not match current resource ETag</e:message>
	                <e:given-etag>{$incoming-etag}</e:given-etag>
	                <e:current-etag>{$record-etag}</e:current-etag>
	            </e:etag-mismatch>
	        </e:errors>,
	        xdmp:set-response-content-type ($const:CT-ERROR-XML),
	        xdmp:set-response-code (409, "Conflict")
		)
)
else (
	xdmp:set-response-code (204, "No Content")
)
