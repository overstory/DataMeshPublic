xquery version '1.0-ml';

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "../lib/constants.xqy";
import module namespace r="urn:overstory:modules:data-mesh:handlers:lib:records" at "../lib/lib-records.xqy";

declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";

declare option xdmp:output "indent=yes";

declare variable $api-config as document-node()? := r:fetch-record-with-short-resource-uri ($const:API-DOCUMENT-URI);

if (fn:exists($api-config))
then (
    xdmp:set-response-code (200, "OK"),
    xdmp:set-response-content-type ($const:CT-RECORD-XML),
    r:prepare-record-resource ($api-config)
) else (
    xdmp:set-response-code (404, "Not Found")
)
