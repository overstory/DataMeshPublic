xquery version '1.0-ml';

module namespace uris="urn:overstory:modules:data-mesh:handlers:lib:search";

import module namespace r="urn:overstory:modules:data-mesh:handlers:lib:records" at "lib-records.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "constants.xqy";
import module namespace p="com.blakeley.xqysp" at "xqysp.xqy";

declare namespace e = "http://ns.overstory.co.uk/namespaces/error";
declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";
declare namespace oss = "http://ns.overstory.co.uk/namespaces/search";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace atom = "http://www.w3.org/2005/Atom";

declare option xdmp:output "indent=yes";

declare variable $word-query-options := ("case-insensitive", "diacritic-insensitive", "punctuation-insensitive");

(: ---------------------------------------------------------- :)
(: GET-sparql-search :)
(: ---------------------------------------------------------- :)

(: Perform SPARQL query and serialize the results :)

declare function perform-sparql-search (
    $sparql-query as xs:string
) as xs:string*
{
    let $sparql-result-bindings := sem:sparql ($sparql-query, (), (), (), ())
    return map:get ($sparql-result-bindings, 'search')
};

(: Build response from SPARQL results :)

declare function build-sparql-search-response(
    $search-criteria as element(oss:search-criteria),
    $results as xs:string*,
    (:$sparql-query as xs:string?,
    $cts-query as cts:query?,
    $collection as xs:string:)
    $total-hits as xs:integer
) as element(oss:result)
{
	(:let $total-hits := if (starts-with(xdmp:version(), '8')) then total-hits-sparql ($sparql-query, $cts-query, $collection) else fn:count($results):)
    let $first := $search-criteria/oss:first
    let $page-size := $search-criteria/oss:ipp
    let $last := if ($total-hits = 0) then 1 else if (($first + $page-size) > $total-hits) then $total-hits else ($first + ($page-size - 1))
    return
        <oss:result first="{$first}" last="{$last}" page-size="{$page-size}" total-hits="{$total-hits}" request-url="{$search-criteria/oss:request-url}" xmlns:oss="http://ns.overstory.co.uk/namespaces/search">
        {
        	$search-criteria,
            for $value in $results
            return <oss:uri>{$value}</oss:uri>
        }
        </oss:result>
};

(: Build SPARQL query to be run :)

declare function build-sparql-query (
    $search-criteria as element(oss:search-criteria)
) as xs:string?
{
    if ( fn:not (data ($search-criteria/oss:refers-to)) and fn:not (data ($search-criteria/oss:referenced-by)) and ($search-criteria/oss:sparql/string()) )
    then (
        fn:concat(
        fn:string-join (build-prefix-list (), " "), (" "),
        $search-criteria/oss:sparql/string()
        )
    )
    else
        let $refers-to :=
            if ($search-criteria/oss:refers-to/string())
            then
                if ($search-criteria/oss:predicate/string())
                then fn:concat('?search ', build-sparql-value ($search-criteria/oss:predicate/string()),' ', build-sparql-value ($search-criteria/oss:refers-to/string()), ' . ')
                else fn:concat('?search ?p ', build-sparql-value ($search-criteria/oss:refers-to/string()), ' . ')
            else('')

        let $referenced-by :=
            if ($search-criteria/oss:referenced-by/string())
            then (
                if ($search-criteria/oss:predicate/string())
                then fn:concat (build-sparql-value ($search-criteria/oss:referenced-by/string()),' ', build-sparql-value ($search-criteria/oss:predicate/string()), ' ?search . ')
                else fn:concat (build-sparql-value ($search-criteria/oss:referenced-by/string()), ' ?p ?search . ') )
            else('')

        let $type :=
            if ($search-criteria/oss:type/string())
            then ( fn:concat (' ?search a ', build-sparql-value ($search-criteria/oss:type/string()), ' . '))
            else('')
        (: filter shouldn't be applied to refers-to as this will always return a subject i.e. record uri :)
        (: filter for referenced-by checks for a 1.0 SPARQL negation (proper negation have been implemented in SPARQL 1.1
        	Do not display rdf:type as a result if matched by SPARQL query :)
        let $filter := if ($referenced-by) then 'OPTIONAL { ' || build-sparql-value ($search-criteria/oss:referenced-by/string()) || ' rdf:type ?rdftype . FILTER (?search = ?rdftype) . } 
		FILTER ( isIri (?search) &amp;&amp; !BOUND(?rdftype) )' else (" FILTER ( isIri (?search) ) .")
		
		let $ipp := $search-criteria/oss:ipp/string()
		let $first := $search-criteria/oss:first/string()
		
		let $pagination := 
			if ($search-criteria/oss:page = "1") 
			then fn:concat ( "LIMIT ", $ipp )
			else fn:concat ( "OFFSET ", (xs:int ($first) - 1), " LIMIT ", $ipp )
		
        let $sparql :=
            fn:concat ( fn:string-join (build-prefix-list (), " "), (" "), 'SELECT DISTINCT ?search WHERE { ', $refers-to, $referenced-by, $type, $filter, ' } ', $pagination )

        return $sparql
};

declare function build-sparql-query-without-pagination (
    $search-criteria as element(oss:search-criteria)
) as xs:string?
{
    if ( fn:not (data ($search-criteria/oss:refers-to)) and fn:not (data ($search-criteria/oss:referenced-by)) and ($search-criteria/oss:sparql/string()) )
    then (
        fn:concat(
        fn:string-join (build-prefix-list (), " "), (" "),
        $search-criteria/oss:sparql/string()
        )
    )
    else
        let $refers-to :=
            if ($search-criteria/oss:refers-to/string())
            then
                if ($search-criteria/oss:predicate/string())
                then fn:concat('?search ', build-sparql-value ($search-criteria/oss:predicate/string()),' ', build-sparql-value ($search-criteria/oss:refers-to/string()), ' . ')
                else fn:concat('?search ?p ', build-sparql-value ($search-criteria/oss:refers-to/string()), ' . ')
            else('')

        let $referenced-by :=
            if ($search-criteria/oss:referenced-by/string())
            then (
                if ($search-criteria/oss:predicate/string())
                then fn:concat (build-sparql-value ($search-criteria/oss:referenced-by/string()),' ', build-sparql-value ($search-criteria/oss:predicate/string()), ' ?search . ')
                else fn:concat (build-sparql-value ($search-criteria/oss:referenced-by/string()), ' ?p ?search . ') )
            else('')

        let $type :=
            if ($search-criteria/oss:type/string())
            then ( fn:concat (' ?search a ', build-sparql-value ($search-criteria/oss:type/string()), ' . '))
            else('')
        (: filter shouldn't be applied to refers-to as this will always return a subject i.e. record uri :)
        (: filter for referenced-by checks for a 1.0 SPARQL negation (proper negation have been implemented in SPARQL 1.1
        	Do not display rdf:type as a result if matched by SPARQL query :)
        let $filter := if ($referenced-by) then 'OPTIONAL { ' || build-sparql-value ($search-criteria/oss:referenced-by/string()) || ' rdf:type ?rdftype . FILTER (?search = ?rdftype) . } 
		FILTER ( isIri (?search) &amp;&amp; !BOUND(?rdftype) )' else (" FILTER ( isIri (?search) ) .")
	
		
        let $sparql :=
            fn:concat ( fn:string-join (build-prefix-list (), " "), (" "), 'SELECT DISTINCT ?search WHERE { ', $refers-to, $referenced-by, $type, $filter, ' } ' )

        return $sparql
};

declare function build-sparql-query-for-total-hits (
    $search-criteria as element(oss:search-criteria)
) as xs:string?
{
    if ( fn:not (data ($search-criteria/oss:refers-to)) and fn:not (data ($search-criteria/oss:referenced-by)) and ($search-criteria/oss:sparql/string()) )
    then (
        fn:concat(
        fn:string-join (build-prefix-list (), " "), (" "),
        $search-criteria/oss:sparql/string()
        )
    )
    else
        let $refers-to :=
            if ($search-criteria/oss:refers-to/string())
            then
                if ($search-criteria/oss:predicate/string())
                then fn:concat('?search ', build-sparql-value ($search-criteria/oss:predicate/string()),' ', build-sparql-value ($search-criteria/oss:refers-to/string()), ' . ')
                else fn:concat('?search ?p ', build-sparql-value ($search-criteria/oss:refers-to/string()), ' . ')
            else('')

        let $referenced-by :=
            if ($search-criteria/oss:referenced-by/string())
            then (
                if ($search-criteria/oss:predicate/string())
                then fn:concat (build-sparql-value ($search-criteria/oss:referenced-by/string()),' ', build-sparql-value ($search-criteria/oss:predicate/string()), ' ?search . ')
                else fn:concat (build-sparql-value ($search-criteria/oss:referenced-by/string()), ' ?p ?search . ') )
            else('')

        let $type :=
            if ($search-criteria/oss:type/string())
            then ( fn:concat (' ?search a ', build-sparql-value ($search-criteria/oss:type/string()), ' . '))
            else('')
        (: filter shouldn't be applied to refers-to as this will always return a subject i.e. record uri :)
        (: filter for referenced-by checks for a 1.0 SPARQL negation (proper negation have been implemented in SPARQL 1.1
        	Do not display rdf:type as a result if matched by SPARQL query :)
        let $filter := if ($referenced-by) then 'OPTIONAL { ' || build-sparql-value ($search-criteria/oss:referenced-by/string()) || ' rdf:type ?rdftype . FILTER (?search = ?rdftype) . } 
		FILTER ( isIri (?search) &amp;&amp; !BOUND(?rdftype) )' else (" FILTER ( isIri (?search) ) .")
		
        let $sparql :=
            fn:concat ( fn:string-join (build-prefix-list (), " "), (" "), 'SELECT (COUNT(?search) AS ?count) WHERE { ', $refers-to, $referenced-by, $type, $filter, ' } ' )

        return $sparql
};

declare function build-paginaition-predefined-sparql-query (
	 $sparql as xs:string,
	 $page as xs:string?,
	 $ipp as xs:string?,
	 $first as xs:integer?
) as xs:string
{
	let $pagination := 
			if ($page = "1") 
			then fn:concat ( "LIMIT ", $ipp )
			else fn:concat ( "OFFSET ", (xs:int ($first) - 1), " LIMIT ", $ipp )
	return 
		($sparql || ' ' || $pagination)
};

(: ---------------------------------------------------------- :)
(: GET-record-search :)
(: ---------------------------------------------------------- :)

(: Decide which query should be run :)

declare function perform-search (
    $sparql-query as xs:string?,
    $cts-query as cts:query?,
    $search-criteria as element(oss:search-criteria),
    $collection as xs:string
) as element(oss:result)
{
    if (fn:empty ($sparql-query))
    then build-cts-search-response ($search-criteria, perform-cts-search ($search-criteria, $cts-query, $collection), total-hits-cts ($cts-query, $collection))
    else build-sparql-search-response ($search-criteria, perform-mixed-search ($search-criteria, $sparql-query, $cts-query, $collection), (:$sparql-query, $cts-query, $collection:) total-hits-sparql ($sparql-query, $cts-query, $collection, $search-criteria))
};

(: SPARQL with cts-query :)

declare function perform-mixed-search (
    $search-criteria as element(oss:search-criteria),
    $sparql-query as xs:string,
    $cts-query as cts:query?,
    $collection as xs:string
) as xs:string*
{
    let $sparql-result-bindings := sem:sparql ($sparql-query, (), (fn:concat ('default-graph=',$collection)), $cts-query, ())
    return map:get ($sparql-result-bindings, 'search')
};


(: Perform cts:query when SPARQL does not exists :)

declare function perform-cts-search (
    $search-criteria as element(oss:search-criteria),
    $cts-query as cts:query?,
    $collection as xs:string
) as document-node()*
{
    let $first := $search-criteria/oss:first
    let $last := $search-criteria/oss:last
    return
        if (fn:exists ($cts-query))
        then cts:search (fn:collection ($collection), $cts-query) [$first to $last]
        else fn:collection ($collection)[$first to $last]
};

declare function perform-record-collection-search (
    $search-criteria as element (oss:search-criteria),
    $sparql-query as xs:string?,
    $cts-query as cts:query?
) as xs:string*
{
    let $sparql-result-bindings := sem:sparql($sparql-query, (), (fn:concat ('default-graph=',$const:RECORD-COLLECTION),'checked'), $cts-query, ())
    return map:get ($sparql-result-bindings, 'search')
};

declare function total-hits-cts (
    $cts-query as cts:query?,
    $collection as xs:string
) as xs:integer
{
    if (fn:exists ($cts-query))
    then xdmp:estimate (cts:search (fn:collection ($collection), $cts-query))
    else xdmp:estimate (fn:collection ($collection))
};

declare function total-hits-sparql (
	$sparql-query as xs:string?,
	$cts-query as cts:query?,
	$collection as xs:string,
	$search-criteria as element(oss:search-criteria)
) as xs:integer?
{
	let $predefined-sparql := $search-criteria/oss:sparql/string()
	return
		if (starts-with(xdmp:version(), '8')) 
		then 
			if ($predefined-sparql)
			then 
				let $sparql-count-query := fn:replace ($predefined-sparql, 'SELECT DISTINCT \?search', 'SELECT (COUNT(?search) AS ?count)')
				let $sparql-count-query := fn:replace ($sparql-count-query, 'SELECT \?search', 'SELECT (COUNT(?search) AS ?count)')
				let $sparql-count-query := fn:replace ($sparql-count-query, 'OFFSET \d+', '')
				let $sparql-count-query := fn:replace ($sparql-count-query, 'LIMIT \d+', '')
				return map:get (sem:sparql ($sparql-count-query, (), (fn:concat ('default-graph=',$collection)), $cts-query, ()), 'count')
			else 
				let $sparql := build-sparql-query-for-total-hits ($search-criteria)
				return map:get (sem:sparql ($sparql), 'count')
		else 
			if ($predefined-sparql) 
			then 
				let $predefined-sparql := fn:replace ($predefined-sparql, 'OFFSET \d+', '')
				let $predefined-sparql := fn:replace ($predefined-sparql, 'LIMIT \d+', '')
				return fn:count(sem:sparql($predefined-sparql))
			else 
				let $sparql := build-sparql-query-without-pagination ($search-criteria)
				return fn:count(sem:sparql ($sparql))
};
(: Build cts:query response :)

declare function build-cts-search-response(
    $search-criteria as element(oss:search-criteria),
    $results as document-node()*,
    $total-hits as xs:integer
) as element(oss:result)
{
    let $first := $search-criteria/oss:first
    let $page-size := $search-criteria/oss:ipp
    let $last := if ($total-hits = 0) then 1 else if (($first + $page-size) > $total-hits) then $total-hits else ($first + ($page-size - 1))
    
    return
        <oss:result first="{$first}" last="{$last}" page-size="{$page-size}" total-hits="{$total-hits}" request-url="{$search-criteria/oss:request-url}" xmlns:oss="http://ns.overstory.co.uk/namespaces/search">
        {
        	$search-criteria,
            for $document in $results
            return <oss:uri>{$document//osc:uri/fn:string()}</oss:uri>
        }
        </oss:result>
};

(: Entry point for building cts queries :)

declare function build-cts-query (
    $search-criteria as element(oss:search-criteria)
) as cts:query?
{
    let $term-query := terms-query ($search-criteria/oss:terms/string-trim(.))
    let $ids-query := ids-query ($search-criteria/oss:ids/string())
    let $date-query := date-query ($search-criteria)
    let $queries := wrap-in-and-query (($term-query, $ids-query, $date-query))
    return $queries
};

(: date query :)

declare function date-query (
    $search-criteria as element(oss:search-criteria)
) as cts:query?
{
    let $created-before := $search-criteria/oss:created-before/string()
    let $created-after := $search-criteria/oss:created-after/string()
    let $updated-before := $search-criteria/oss:updated-before/string()
    let $updated-after := $search-criteria/oss:updated-after/string()

    let $created-before-query :=
        if ($created-before castable as xs:dateTime) then cts:element-range-query(xs:QName("osc:created"), "<", xs:dateTime($created-before)) else ()
    let $created-after-query :=
        if ($created-after castable as xs:dateTime) then cts:element-range-query(xs:QName("osc:created"), ">", xs:dateTime($created-after)) else ()
    let $updated-before-query :=
        if ($updated-before castable as xs:dateTime) then cts:element-range-query(xs:QName("osc:updated"), "<", xs:dateTime($updated-before)) else ()
    let $updated-after-query :=
        if ($updated-after castable as xs:dateTime) then cts:element-range-query(xs:QName("osc:updated"), ">", xs:dateTime($updated-after)) else ()

    return wrap-in-and-query( ($created-before-query, $created-after-query, $updated-before-query, $updated-after-query) )
};

(: terms text query :)

declare private function terms-query (
	$terms as xs:string
) as cts:query?
{
	let $parsed-query as cts:query? := parse ($terms)
	return
        if (fn:empty($parsed-query))
	   then ()
	   else cts:or-query(($parsed-query, ()))
};

declare private function ids-query (
    $ids as xs:string
) as cts:query?
{
    if (fn:not ($ids))
    then ()
    else cts:element-value-query (xs:QName ("osc:uri"), tokenize-ids($ids), "exact", 15)
};

declare private function wrap-in-and-query (
	$queries as cts:query*
) as cts:query?
{
	if (fn:empty ($queries))
	then ()
	else
       	if (fn:count ($queries) = 1)
       	then $queries
       	else cts:and-query ($queries)
};

declare function tokenize-ids (
    $ids as xs:string

) as xs:string*
{
    fn:tokenize ($ids, '(\s*,\s*)|(\s+)')
};

declare function select-collection (
	$search-all as xs:boolean
) as xs:string
{
	if ($search-all)
    then $const:RECORD-COLLECTION
    else $const:SEARCHABLE-COLLECTION
};


(: ---------------------------------------------------------- :)
(: Search Support :)
(: ---------------------------------------------------------- :)

declare function parse (
	$qs as xs:string?
) as cts:query?
{
	eval (p:parse ($qs))
};

declare function string-trim (
	$arg as xs:string?
)  as xs:string
{
	fn:replace (fn:replace ($arg, '\s+$',''), '^\s+','')
};

declare function eval (
	$n as element()
) as cts:query?
{
	(: walk the AST, transforming AST XML into cts:query items :)
	typeswitch($n)
	case element(p:expression) return expr($n/@op, eval($n/*))
	(: NB - no eval, since we may need to handle literals in qe:field too :)
	(: This code works as long as your field names match the QNames.
	: If they do not, replace xs:QName with a lookup function.
	:)
	case element(p:field) return field (xs:QName($n/@name/fn:string()), $n/@op, $n/*)
	case element(p:group) return if (fn:count($n/*, 2) lt 2) then eval($n/*) else cts:and-query(eval($n/*))
	(: NB - interesting literals should be handled by the cases above :)
	case element(p:literal) return cts:word-query ($n, $word-query-options)
	case element(p:root) return ( if (fn:count($n/*, 2) lt 2) then eval($n/*) else cts:and-query(eval($n/*)))
	default return fn:error((), 'UNEXPECTED')
};

declare private function expr (
	$op as xs:string,
	$list as cts:query*
) as cts:query?
{
	let $op := fn:upper-case ($op)

	return
	(: To implement a new operator, simply add it to this code :)
	if (fn:empty($list)) then ()
	(: simple boolean :)
	else if (fn:empty($op) or $op eq 'AND')
	then cts:and-query($list)
	else if ($op = ('NOT', '-'))
	then cts:not-query($list)
	else if ($op = ('OR','|'))
	then cts:or-query($list)
	(: near and variations :)
	else if ($op eq 'NEAR')
	then cts:near-query($list)
	else if (fn:starts-with($op, 'NEAR/'))
	then cts:near-query ($list, xs:double(fn:substring-after($op, 'NEAR/')))
	else if ($op eq 'ONEAR')
	then cts:near-query($list, (), 'ordered')
	else if (fn:starts-with($op, 'ONEAR/'))
	then cts:near-query ($list, xs:double(fn:substring-after($op, 'ONEAR/')), 'ordered')
	else fn:error((), 'UNEXPECTED')
};

declare private function field (
	$qnames as xs:QName+,
	$op as xs:string?,
	$list as element()*
) as cts:query?
{
  (: This function leaves many problems unresolved.
   : What if $list contains sub-expressions from nested groups?
   : What if $list contains non-string values for range queries?
   : What if a range-query needs a special collation?
   : Handle these corner-cases if you need them.
   :)
	if (fn:empty($list))
	then cts:element-query($qnames, cts:and-query(()))
	else if ($op = ('>', '>=', '<', '<='))
	then cts:element-range-query ($qnames, $op, $list)
	else if ($op eq '=')
	then cts:element-value-query($qnames, $list)
	else cts:element-word-query($qnames, $list)
};

declare function build-prefix-list (
) as xs:string*
{
    let $prefixes := cts:search(collection('http://rdf.overstory.co.uk/rdf/terms/Prefix'), cts:element-value-query( xs:QName("osc:prefix-uri"), '*', ("wildcarded")))
    for $doc in $prefixes
    return fn:concat('PREFIX ', $doc//osc:prefix-name, ': ', '<', $doc//osc:prefix-uri, '> ')
};

declare function build-sparql-value (
    $input as xs:string
) as xs:string?
{
    (: URL :)
    if (fn:matches ($input, "^(https?|ftp|file)://.+$") )
    then (fn:concat('<',$input,'>'))
    (: URN :)
    (:else if (fn:matches($input, "^urn:[a-z0-9()+,\-.:=@;$_!*'%/?#]+$")):)
    else if (fn:matches($input, "urn:[a-z0-9]{1}[a-z0-9\-.]{1,31}:[a-z0-9_,:=@;!'%/#\(\)\+\-\.\$\*\?]+"))
    then (fn:concat('<',$input,'>'))
    (: CURIE :)
    else if (fn:matches($input, "[A-z*\d*]+:[A-z*\d*]+$"))
    then ($input)
    (: Text :)
    else (fn:concat('"',$input,'"'))
};

declare function validate-curie (
	$input as xs:string
) as xs:boolean
{
	if (fn:matches ($input, "^(https?|ftp|file)://.+$") )
    then fn:true()
    (: URN :)
    (:else if (fn:matches($input, "^urn:[a-z0-9()+,\-.:=@;$_!*'%/?#]+")):)
    else if (fn:matches($input, "urn:[a-z0-9]{1}[a-z0-9\-.]{1,31}:[a-z0-9_,:=@;!'%/#\(\)\+\-\.\$\*\?]+"))
    then fn:true()
    (: CURIE :)
    else if (fn:matches($input, "[A-z*\d*]+:[A-z*\d*]+$"))
    then (
    	let $prefix := fn:substring-before ($input, ":")
    	let $prefix-uri := r:build-prefix-uri ($prefix)
    	return r:prefix-exists ($prefix-uri)
    )
    else fn:false()
};


(: ---------------------------------------------------------- :)
(: Obsolete :)
(: ---------------------------------------------------------- :)

(: ---------------------------------------------------------- :)
(: ATOM responses :)
(: ---------------------------------------------------------- :)

(: atom response when SPARQL is used for search :)

declare function build-sparql-atom-response (
    $results as node(),
    $search-criteria as element(oss:search-criteria)
) as element(atom:feed)
{
    let $total-hits := fn:count($results//sparql:result)
    let $current-first-item := $search-criteria/oss:first-item
    let $current-page := $search-criteria/oss:page
    let $ipp := $search-criteria/oss:ipp

    (: todo: rethink this? :)
    let $from := xs:int($current-page * $ipp - $ipp + 1)
    let $to := xs:int($from + $ipp - 1)

    return
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:osc="http://ns.overstory.co.uk/namespaces/datamesh/content" xmlns:oss="http://ns.overstory.co.uk/namespaces/search">
            <id>/record</id>
            <title type="text">Search feed</title>
            <link href="{$search-criteria/oss:request-url}" rel="self"/>
            {
                build-prev-link($search-criteria),
                build-next-link($search-criteria, $total-hits),
                $search-criteria
            }
            <updated>{fn:current-dateTime()}</updated>
            {
                for $value at $position in $results//sparql:result [$from to $to]
                return (<entry>{$value}</entry>)
            }
        </feed>
};

(: atom response when cts query is used for search :)

declare function build-cts-atom-response (
    $results as document-node()*,
    $search-criteria as element(oss:search-criteria)
) as element(atom:feed)
{
    let $total-hits := fn:count($results//osc:record)
    let $current-first-item := $search-criteria/oss:first-item
    let $current-page := $search-criteria/oss:page
    let $ipp := $search-criteria/oss:ipp

    (: todo: rethink this? :)
    let $from := xs:int($current-page * $ipp - $ipp + 1)
    let $to := xs:int($from + $ipp - 1)

    return
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:osc="http://ns.overstory.co.uk/namespaces/datamesh/content" xmlns:oss="http://ns.overstory.co.uk/namespaces/search">
            <id>/record</id>
            <title type="text">Search feed</title>
            <link href="{$search-criteria/oss:request-url}" rel="self"/>
            {
                build-prev-link($search-criteria),
                build-next-link($search-criteria, $total-hits),
                $search-criteria
            }
            <updated>{fn:current-dateTime()}</updated>
            {
                for $value at $position in $results//osc:record [$from to $to]
                return
                    <entry>
                    <link href="/record/{$value/osc:uri}" rel="self"/>
                    <id>{$value/osc:uri}</id>
                    <updated>get-some-sort-of-date?</updated>
                    <content type="application/record+xml">
                        {$value}
                    </content>
                    </entry>
            }
        </feed>
};

(: build next link for atom response :)

declare function build-next-link (
    $search-criteria as element (oss:search-criteria),
    $total-hits as xs:int
) (:as element (atom:link)?:)
{
    let $request-url := $search-criteria/oss:request-url/string()
    let $current-page := xs:int ($search-criteria/oss:page/string())
    let $ipp := xs:int ($search-criteria/oss:ipp/string())
    let $current-first-item := xs:int ($search-criteria/oss:first-item/string())

    let $new-page := ( if ($current-first-item = 0 and $total-hits > $current-page*$ipp ) then ( $current-page + 1 ) else ( 0 ) )
    let $new-first-item := ( if ($current-first-item != 0) then ( $current-first-item + $ipp ) else ( 0 ) )

    return
    (
        if ($new-first-item = 0 and fn:not ($new-page = 0))
        then (
            if (fn:matches ($request-url, 'page=(\d+)'))
            then ( <atom:link href="{fn:replace ($request-url, 'page=(\d+)', fn:concat('page=', $new-page))}" rel="next"/> )
            else ( <atom:link href="{fn:concat($request-url, '?page=', $new-page)}" rel="next"/>)
        )
        else ()
    )
};

(: build previous link for atom response :)

declare function build-prev-link (
    $search-criteria as element (oss:search-criteria)
) (:as element (atom:link)?:)
{
    let $request-url := $search-criteria/oss:request-url
    let $current-page := xs:int ($search-criteria/oss:page)
    let $ipp := xs:int ($search-criteria/oss:ipp)
    let $current-first-item := xs:int ($search-criteria/oss:first-item)

    let $new-page := ( if ($current-first-item = 0) then ( $current-page - 1 ) else ( 0 ) )
    let $new-first-item := ( if ($current-first-item != 0) then ( $current-first-item - $ipp ) else ( 0 ) )

    return
    (
        if ($new-first-item = 0 and $new-page >= 1)
        then (
            if (fn:matches ($request-url, 'page=(\d+)'))
            then ( <atom:link href="{fn:replace ($request-url, 'page=(\d+)', fn:concat('page=', $new-page))}" rel="prev"/> )
            else ( <atom:link href="{fn:concat($request-url, '?page=', $new-page)}" rel="prev"/>)
        )
        else ()
    )
};


(:


    let $prefixes := build-prefix-map()
    (:
    if refers-to is used then subject is in scope
    if referenced-by is used then object is in scope
    :)
    let $search-criteria :=
        if ($refers-to)
        then ('?s')
        else if ($referenced-by)
        then ('?o')
            else ('?s ?p ?o')
    (:

    /record/type/foaf:Person?referenced-by=urn:overstory.co.uk:id:engagement:12345&refers-to=urn:overstory.co.uk:id:address:1


    /record/type/foaf:Person?referenced-by=urn:overstory.co.uk:id:engagement:12345

    SELECT ?s ?p ?o WHERE { ?s ?p ?o . ?s/?o a type }

    SELECT ?s ?p ?o WHERE {
        (if $refersto): ?s ?p $referesto .
        (if $type and $refersto): ?s a foaf:Person.
        (if $referencedby): $referencedby ?p ?o .
        (if $type and $referencedby): ?o a foaf:Person.
    }


    SELECT ?o WHERE { <urn:overstory.co.uk:id:engagement:12345> ?p ?o . ?o a foaf:Person }
    :)
    let $subject :=
        if ($referenced-by)
        then ( build-sparql-value ($referenced-by) )
        else ('?s') (:xs:string ('?s'):)

    let $predicate :=
        if ($predicate)
        then ( build-sparql-value ($predicate) )
        else ('?p')
    (:
    /record/type/foaf:Person?refers-to=urn:overstory.co.uk:id:address:1
    SELECT ?s WHERE { ?s ?p <urn:overstory.co.uk:id:address:1> . ?s a foaf:Person }
    SELECT ?o WHERE { <urn:overstory.co.uk:id:engagement:12345> ?p ?o . ?o a foaf:Person }

    :)
    let $object :=
        if ($refers-to)
        then ( build-sparql-value ($refers-to) )
        else ('?o')
    (:
    /record/type/*foaf:Person*?...
    SELECT ?s ?p ?o WHERE { ?s ?p ?o . ?s/?o a foaf:Person }
    :)
    let $type :=
        if ($type)
        then ( build-type-sparql ($type, $refers-to, $referenced-by) )
        else ('')
    let $build-sparql := fn:concat ('SELECT ',$search-criteria,' WHERE {', ' ', $subject, ' ',$predicate, ' ',$object, ' ','. ',$type,' }' )

    return
        let $merge := <sparql>{$prefixes, for $value in $build-sparql return $value}</sparql>
        return $merge/string()
:)

(:declare function perform-search(
    $type as xs:string,
    $refers-to as xs:string,
    $referenced-by as xs:string,
    $predicate as xs:string,
    $sparql as xs:string,
    $page as xs:string,
    $ipp as xs:string,
    $first-item as xs:string
)
{
    let $build-sparql := if ($sparql) then ($sparql) else (build-sparql($type,$refers-to,$referenced-by,$predicate))
    let $run-sparql := sem:query-results-serialize(sem:sparql($build-sparql))
    let $total-hits := fn:count($run-sparql)
    let $search-criteria := r:build-search-criteria($type,$refers-to,$referenced-by,$predicate,$build-sparql,xs:int($page),xs:int($ipp),xs:int($first-item),$total-hits)
    let $atom-response := r:simple-build-atom-response ($run-sparql, 'sparql:binding', $search-criteria)
    return (
        xdmp:set-response-code (200, "OK"),
        xdmp:set-response-content-type ($const:CT-ATOM-XML),
        $atom-response
    )
};:)




