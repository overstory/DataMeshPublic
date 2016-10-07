xquery version '1.0-ml';

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "../lib/constants.xqy";
import module namespace s="urn:overstory:modules:data-mesh:handlers:lib:search" at "../lib/lib-search.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare namespace e = "http://ns.overstory.co.uk/namespaces/error";
declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";
declare namespace oss = "http://ns.overstory.co.uk/namespaces/search";
declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace mlerror = "http://marklogic.com/xdmp/error";

declare option xdmp:output "indent=yes";

(: Parameters :)
declare variable $terms := xdmp:get-request-field ("terms", ());
declare variable $ids := xdmp:get-request-field ("ids", ());

declare variable $refers-to := xdmp:get-request-field ("refers-to", ());
declare variable $predicate := xdmp:get-request-field ("predicate", ());
declare variable $referenced-by := xdmp:get-request-field ("referenced-by", ());
declare variable $type := xdmp:get-request-field ("type", ());

declare variable $created-before := xdmp:get-request-field ("created-before", ());
declare variable $created-after := xdmp:get-request-field ("created-after", ());

declare variable $updated-before := xdmp:get-request-field ("updated-before", ());
declare variable $updated-after := xdmp:get-request-field ("updated-after", ());

declare variable $search-all := xdmp:get-request-field("search-all", ());

declare variable $page := xdmp:get-request-field ("page", '1');
declare variable $ipp := xdmp:get-request-field ("ipp", '10');
declare variable $first-item := xdmp:get-request-field ("first-item", ());

(: declare variable $accept-type as xs:string? := xdmp:get-request-header ("Accept", $const:CT-XML); :)

declare variable $search-criteria :=
    let $first := if ($first-item castable as xs:integer) then xs:integer ($first-item) else ()
    let $first := ($first-item, (xs:integer ($page) * xs:integer ($ipp) - xs:integer ($ipp) + 1))[1]
    let $last := xs:integer ($first) + (xs:integer ($ipp) - 1)
    return
        <oss:search-criteria>
            <oss:request-url>{xdmp:get-original-url ()}</oss:request-url>
            <oss:terms>{$terms}</oss:terms>
            <oss:ids>{$ids}</oss:ids>
            <oss:type>{$type}</oss:type>
            <oss:search-all>{$search-all}</oss:search-all>
            <oss:predicate>{$predicate}</oss:predicate>
            <oss:refers-to>{$refers-to}</oss:refers-to>
            <oss:referenced-by>{$referenced-by}</oss:referenced-by>
            <oss:page>{$page}</oss:page>
            <oss:ipp>{$ipp}</oss:ipp>
            <oss:first-item>{$first-item}</oss:first-item>
            <oss:first>{$first}</oss:first>
            <oss:last>{$last}</oss:last>
            <oss:created-before>{$created-before}</oss:created-before>
            <oss:created-after>{$created-after}</oss:created-after>
            <oss:updated-before>{$updated-before}</oss:updated-before>
            <oss:updated-after>{$updated-after}</oss:updated-after>
        </oss:search-criteria>;

let $validate-type := (s:validate-curie ($type), fn:true ())[1]
let $validate-refers-to := (s:validate-curie ($refers-to), fn:true ())[1]
let $validate-referenced-by := (s:validate-curie ($referenced-by), fn:true ())[1]
return 
	if (fn:not ($validate-type and $validate-refers-to and $validate-referenced-by))
	then (
		<e:errors>
			<e:incorrect-parameter>
				<e:message>Prefix used in a request parameter could not be found</e:message>
				{
					if (fn:not ($validate-type)) then (<e:parameter-name>type</e:parameter-name>,<e:parameter-value>{$type}</e:parameter-value>) else (),
					if (fn:not ($validate-refers-to)) then (<e:parameter-name>refers-to</e:parameter-name>,<e:parameter-value>{$refers-to}</e:parameter-value>) else (),
					if (fn:not ($validate-referenced-by)) then (<e:parameter-name>referenced-by</e:parameter-name>,<e:parameter-value>{$referenced-by}</e:parameter-value>) else ()
				}
			</e:incorrect-parameter>
		</e:errors>,
		xdmp:set-response-code (400, "Bad Request"),
        xdmp:set-response-content-type ($const:CT-ERROR-XML)
		)
	else 
		let $collection as xs:string := if ($search-all = 'true') then s:select-collection (fn:true()) else s:select-collection (fn:false())
		let $sparql-query as xs:string? := if (fn:empty (($refers-to, $referenced-by, $type, $predicate))) then () else s:build-sparql-query ($search-criteria)
		let $cts-query as cts:query? := s:build-cts-query ($search-criteria)
		let $results := s:perform-search ($sparql-query, $cts-query, $search-criteria, $collection)
		let $_ := xdmp:set-response-content-type ($const:CT-ATOM-XML)
		return $results
