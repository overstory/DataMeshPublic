xquery version '1.0-ml';

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "../lib/constants.xqy";
import module namespace rconst="urn:overstory:rest:modules:constants" at "../../rest/lib-rest/constants.xqy";
import module namespace r="urn:overstory:modules:data-mesh:handlers:lib:records" at "../lib/lib-records.xqy";
import module namespace s="urn:overstory:modules:data-mesh:handlers:lib:search" at "../lib/lib-search.xqy";

declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";
declare namespace oss = "http://ns.overstory.co.uk/namespaces/search";

declare option xdmp:output "indent=yes";

declare variable $page := xdmp:get-request-field ("page", "1");
declare variable $ipp := xdmp:get-request-field ("ipp", "10");
declare variable $first-item := xdmp:get-request-field ("first-item", ());
declare variable $content-type := xdmp:get-request-header ("accept", $rconst:MEDIA-TYPE-STANDARD-XML);
declare variable $wants-atom := fn:contains ($content-type, $rconst:MEDIA-TYPE-ATOM_XML);

let $search-criteria :=
    let $first := if ($first-item castable as xs:integer) then xs:integer($first-item) else ()
    let $first := ($first, (xs:integer($page) * xs:integer($ipp) - xs:integer($ipp) + 1))[1]
    let $last := xs:integer($first) + (xs:integer($ipp) - 1)
    return
        <oss:search-criteria>
            <oss:request-url>{xdmp:get-original-url()}</oss:request-url>
            <oss:sparql>{s:build-paginaition-predefined-sparql-query($const:PREFIX-SPARQL, $page, $ipp, $first)}</oss:sparql>
            <oss:page>{$page}</oss:page>
            <oss:ipp>{$ipp}</oss:ipp>
            <oss:first-item>{$first-item}</oss:first-item>
            <oss:first>{$first}</oss:first>
            <oss:last>{$last}</oss:last>
        </oss:search-criteria>

let $sparql-query := $search-criteria/oss:sparql
let $results := s:perform-search ($sparql-query, (), $search-criteria, $const:RECORD-COLLECTION, $wants-atom)
return (
	if ($wants-atom) then xdmp:set-response-content-type ($rconst:MEDIA-TYPE-ATOM_XML) else xdmp:set-response-content-type ($rconst:MEDIA-TYPE-STANDARD-XML),
	$results
)
