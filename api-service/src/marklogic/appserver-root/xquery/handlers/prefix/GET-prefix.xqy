xquery version '1.0-ml';

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "../lib/constants.xqy";
import module namespace r="urn:overstory:modules:data-mesh:handlers:lib:records" at "../lib/lib-records.xqy";

declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";
declare namespace e = "http://ns.overstory.co.uk/namespaces/error";

declare option xdmp:output "indent=yes";

declare variable $prefix := xdmp:get-request-field ("prefix", ());
declare variable $prefix-uri := r:build-prefix-uri ($prefix);

if (r:prefix-exists ($prefix-uri))
then (
	let $record as document-node()? := r:document-find-by-uri ($prefix-uri)
	return (
		xdmp:add-response-header ("ETag", r:etag-for-record ($record)),
		xdmp:set-response-code (200, "OK"),
		if (xdmp:get-request-method() = "HEAD")
		then ()
		else (
			xdmp:set-response-content-type ($const:CT-RECORD-XML),
			r:prepare-record-resource ($record)
		)
	)
)
else (
    xdmp:set-response-code (404, "Not Found"),
    xdmp:set-response-content-type ($const:CT-ERROR-XML),
    <e:errors>
	    <e:not-found>
	        <e:message>Prefix not found</e:message>
	        <e:prefix-name>{$prefix}</e:prefix-name>
	        <e:uri>{$prefix-uri}</e:uri>
	    </e:not-found>
	</e:errors>
)
