xquery version '1.0-ml';

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "../lib/constants.xqy";
import module namespace r="urn:overstory:modules:data-mesh:handlers:lib:records" at "../lib/lib-records.xqy";

declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";
declare namespace e = "http://ns.overstory.co.uk/namespaces/error";

declare option xdmp:output "indent=yes";

declare variable $request-uri as xs:string := xdmp:get-request-field ("uri", ());
declare variable $record as document-node()? := r:document-find-by-uri ($request-uri);
declare variable $etag as xs:string := r:etag-for-record ($record);

if (fn:exists($record))
then (
    xdmp:set-response-code (200, "OK"),
    xdmp:set-response-content-type ("application/vnd.overstory.record+xml"),
    xdmp:add-response-header ("ETag", $etag),
	r:prepare-record-resource ($record)
) else (
	<e:errors>
	    <e:not-found>
	        <e:message>Resource not found</e:message>
	        <e:uri>{$request-uri}</e:uri>
	    </e:not-found>
	</e:errors>,
    xdmp:set-response-code (404, "Not Found")
)
