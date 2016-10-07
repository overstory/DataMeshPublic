xquery version '1.0-ml';

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "../lib/constants.xqy";
import module namespace r="urn:overstory:modules:data-mesh:handlers:lib:records" at "../lib/lib-records.xqy";

declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";

declare option xdmp:output "indent=yes";

declare variable $type-doc-uri := $const:TYPE-DOCUMENT-URI;
declare variable $type-doc := fn:doc($type-doc-uri);

declare variable $incoming-doc as element() := r:get-xml-body();
declare variable $type := xdmp:get-request-field ("type", ());
declare variable $uri as xs:string := $incoming-doc/osc:uri;

if (fn:exists ($incoming-doc))
then (
    if ( r:type-exists ($type) )
    then (
    r:update-type($incoming-doc, $type),
    xdmp:set-response-code (201, "Created"),
    xdmp:add-response-header ("Location", '/record/type')
    )
    else (
    r:add-type($incoming-doc),
    xdmp:set-response-code (201, "Created"),
    xdmp:add-response-header ("Location", '/record/type')
    )
)
else (

)



(: Update:

xdmp:node-replace(
cts:search(
collection("urn:overstory.co.uk:collection:rdf-types")/osc:types/osc:type, cts:element-value-query(
      xs:QName("osc:curie"),
      "ost:Asdf"))
, <osc:type>
<osc:uri>http://rdf.overstory.co.uk/rdf/test/Participation</osc:uri>
<osc:curie>ost:Participation</osc:curie>
</osc:type>);

:)

(: Add:

xdmp:node-insert-child(
cts:search(
collection("urn:overstory.co.uk:collection:rdf-types")/osc:types, () )
, 
<osc:type>
<osc:uri>http://rdf.overstory.co.uk/rdf/test/Fdsa</osc:uri>
<osc:curie>ost:Fdsa</osc:curie>
</osc:type>);
:)

