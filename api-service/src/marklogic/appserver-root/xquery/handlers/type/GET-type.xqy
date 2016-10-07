xquery version '1.0-ml';

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "../lib/constants.xqy";
import module namespace r="urn:overstory:modules:data-mesh:handlers:lib:records" at "../lib/lib-records.xqy";

declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";
declare namespace oss = "http://ns.overstory.co.uk/namespaces/search";
declare namespace atom = "http://www.w3.org/2005/Atom";

declare option xdmp:output "indent=yes";

declare variable $page := xdmp:get-request-field ("page", "1");
declare variable $ipp := xdmp:get-request-field ("ipp", "10");
declare variable $first-item := xdmp:get-request-field ("first-item", ());

let $type-sparql := 'SELECT ?search WHERE { ?s <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?search }'
let $search-criteria := 
    let $first := if ($first-item castable as xs:integer) then xs:integer($first-item) else ()
    let $first := ($first-item, (xs:integer($page) * xs:integer($ipp) - xs:integer($ipp) + 1))[1]
    let $last := xs:integer($first) + (xs:integer($ipp) - 1)
    return
        <oss:search-criteria>
            <oss:request-url>{xdmp:get-original-url()}</oss:request-url>
            <oss:type-sparql>{$type-sparql}</oss:type-sparql>
            <oss:page>{$page}</oss:page>
            <oss:ipp>{$ipp}</oss:ipp>
            <oss:first-item>{$first-item}</oss:first-item>
            <oss:first>{$first}</oss:first>
            <oss:last>{$last}</oss:last>
        </oss:search-criteria>
    
let $results (:as element(atom:feed):) := r:get-types($search-criteria)
return $results



(:
try {
    r:get-types($page, $ipp, $first-item)
    } 
catch($e) {
    xdmp:set-response-code (404, "Not Found")
    }:)
(:

declare variable $type-doc := r:type-list();

declare variable $total-hits := fn:count ( $type-doc/osc:type );
declare variable $search-criteria := r:build-search-criteria("","","","","",xs:int($page),xs:int($ipp),xs:int($first-item),$total-hits);


if (fn:exists ($type-doc))
then (
	xdmp:set-response-code (200, "OK"),
	xdmp:set-response-content-type ("application/xml"),
	r:simple-build-atom-response ($type-doc,'osc:type',$search-criteria)
)
else (
	xdmp:set-response-code (404, "Not Found")
)
:)
