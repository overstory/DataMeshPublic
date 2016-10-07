xquery version '1.0-ml';

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "../lib/constants.xqy";
import module namespace s="urn:overstory:modules:data-mesh:handlers:lib:search" at "../lib/lib-search.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";
declare namespace oss = "http://ns.overstory.co.uk/namespaces/search";
declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace mlerror = "http://marklogic.com/xdmp/error";

declare option xdmp:output "indent=yes";

(: Parameters :)

declare variable $sparql as xs:string := xdmp:get-request-field ("sparql", '');
declare variable $page := xdmp:get-request-field ("page", '1');
declare variable $ipp := xdmp:get-request-field ("ipp", '10');
declare variable $first-item := xdmp:get-request-field ("first-item", '0');

declare variable $content-type as xs:string? := xdmp:get-request-header ("Accept", $const:CT-XML);

declare variable $search-criteria :=
    <oss:search-criteria>
        <oss:request-url>{xdmp:get-original-url()}</oss:request-url>
        <oss:sparql>{$sparql}</oss:sparql>
        <oss:page>{$page}</oss:page>
        <oss:ipp>{$ipp}</oss:ipp>
        <oss:first-item>{$first-item}</oss:first-item>
    </oss:search-criteria>;

let $sparql-query := s:build-sparql-query($search-criteria)
let $results as xs:string* := s:perform-sparql-search($sparql-query)
let $response := s:build-sparql-search-response($search-criteria, $results)
let $_ := xdmp:set-response-content-type ($const:CT-XML)
return $response
