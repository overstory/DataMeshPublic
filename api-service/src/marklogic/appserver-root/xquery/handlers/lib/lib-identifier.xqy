xquery version "1.0-ml";
      
module namespace lib="urn:overstory:modules:data-mesh:handlers:lib:identifier";

import module namespace re="urn:overstory:rest:modules:rest:errors" at "../../rest/lib-rest/errors.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

declare namespace e = "http://ns.overstory.co.uk/namespaces/error";
declare namespace i = "http://ns.overstory.co.uk/namespaces/meta/id";
declare namespace m = "http://ns.iop.org/namespaces/resources/meta/content";

declare namespace s ="http://www.w3.org/2005/xpath-functions";

declare option xdmp:output "indent=yes";

declare variable $uri-prefix as xs:string := "urn:iop.org:id:";
declare variable $content-directory-prefix := "/data/mesh/";
declare variable $identifier-directory-prefix := "/identifier/";

declare variable $default-content-type as xs:string := "application/xml";

declare variable $collection-identifier as xs:string := "urn:overstory.co.uk:collection:identifier";

declare variable $xml-options :=
	<options xmlns="xdmp:document-get">
           <format>xml</format>
           <encoding>UTF-8</encoding>
       </options>;

(: ------------------------------------------------------ :)



(: ------------------------------------------------------ :)

(: Identifier functionality specific :)

(: default uri when /identifier is called without any parameters :)
declare function generate-default-uri (
) as xs:string
{
    fn:concat ($uri-prefix, "resource:", generate-uuid-v4(), ":version:1")
};

(: check if identifier-uri exists :)
declare function identifier-exists (
$identifier as xs:string
) as xs:boolean
{
    fn:exists (fn:doc (full-identifier-ml-uri ($identifier) ))
};

(: add directory path to identifier-uri :)
declare function full-identifier-ml-uri (
$identifier as xs:string 
) as xs:string
{
    fn:concat ($identifier-directory-prefix, $identifier)
};

(: generate identifier's system information :)
declare function identifier-system-info (
$etag as xs:string
) as element(i:system)
{
    <i:system xmlns:i="http://ns.overstory.co.uk/namespaces/meta/id">
        <i:created>{lib:current-time()}</i:created>
        <i:etag>{$etag}</i:etag>
    </i:system>
};

(: identifier xml :)
declare function identifier-info (
    $id-system-info (:as element(i:system)?:),
    $annotations (:as element(i:annotation)?:)
) as element(i:identifier-info)
{
    <i:identifier-info xmlns:i="http://ns.overstory.co.uk/namespaces/meta/id">
    {
    $id-system-info,
    $annotations
    }
    </i:identifier-info>
};

(: insert identifier document :)
declare function store-identifier-doc (
	$doc as element(i:identifier-info),
	$identifier as xs:string
) as empty-sequence()
{
	xdmp:document-insert (full-identifier-ml-uri ($identifier),
		$doc, xdmp:default-permissions(), collections-for-new-identifier())
};

(: return collections for identifier :)
declare function collections-for-new-identifier (
) as xs:string*
{
	($collection-identifier)
};

(: get identifier document :)
declare function get-identifier-info (
    $identifier as xs:string
) as node()
{
    fn:doc (full-identifier-ml-uri ($identifier) )
};

(: check incoming identifier annotation xml :)
declare function check-identifier-annotation(
    $annotation as element()
) as xs:boolean
{
    fn:name($annotation) = 'i:annotation'
};

(: get identifier's etag from system info :)
declare function etag-for-identifier (
$doc as element()
) as xs:string
{
    $doc/i:system/i:etag/string()
};


(: identifier template work :)

declare function identifier-from-template (
    $template as xs:string
) as xs:string
{
    let $analyze := fn:analyze-string ($template, '\{.*?\}')
    return process-analyze-string-result ($analyze)
};

declare function process-analyze-string-result (
    $result as element (s:analyze-string-result)
) as xs:string
{
    
    let $result-sequence := 
        for $child in $result/child::*
        return
        ( 
            if (fn:name($child) = 's:non-match')
            then ( process-non-match ($child) )
            else if (fn:name ($child) = 's:match')
            then ( process-match ($child) )
            else ()
        )
        
        return 
        (
            full-identifier-uri (concat-analyze-string-result ($result-sequence))
        )
     
};

declare function full-identifier-uri (
    $uri-suffix as xs:string
)
{
    fn:concat ( $uri-prefix, $uri-suffix )
};

declare function concat-analyze-string-result (
    $result-sequence  (: todo: ask ron how to represent this 'as xs:sequence':)
) as xs:string
{
    fn:string-join($result-sequence,'')
};

declare function process-non-match (
    $non-match as element (s:non-match)
) as xs:string
{
    $non-match/string()
};

declare function process-match (
    $match as element (s:match)
) as xs:string
{   
    process-match-string (discard-match-brackets ($match))
};

declare function discard-match-brackets (
    $match as element(s:match)
) as xs:string
{
    fn:substring-before (fn:substring-after ($match,'{'),'}')
};

declare function process-match-string (
    $match as xs:string
)
{
    if ( $match = 'guid' )
    then ( generate-uuid-v4() )
    else if ( $match = 'now' )
    (: clean the dateTime :)
    then ( lib:current-time() )
    else if ( fn:starts-with ($match, 'doi:') )
    then ( process-doi-template ($match) )
    else if ( fn:starts-with ($match, 'id:') )
    then ( process-id-template ($match) )
    else if ( fn:starts-with ($match, 'time:') )
    then ( process-time-template ($match) )
    else if ( fn:starts-with($match, 'file:') )
    then ( process-file-template ($match) )
    else if ( fn:starts-with ($match, 'min:') )
    then ( process-min-template ($match) )
    else
    ( 'NOT-AVAILABLE')
};

declare function process-doi-template (
    $match as xs:string 
)
{
    fn:replace(fn:substring-after (fn:replace($match, ' ', ''), 'doi:'), '/', '_')
};

declare function process-id-template (
    $match as xs:string 
)
{
    fn:replace(fn:substring-after (fn:replace($match, ' ', ''), 'id:'), '/', '_')
};

(:"marcin{min} :)

declare function process-time-template (
    $match as xs:string 
)
{
    fn:substring-after (fn:replace($match, ' ', ''), 'time:')
};

declare function process-file-template (
    $match as xs:string
)
{
    if (fn:contains($match, '/'))
    then (functx:substring-after-last($match, '/')) 
    else (functx:substring-after-last($match, '\'))
};

declare function process-min-template (
    $match as xs:string
)
{
    'todo'
    (: todo: how to process this if the identifier is not this? :)
};

(: ------------------------------------------------------ :)

(: ------------------------------------------------------ :)

(: uuid/etag generators :)

(: Alternative to sem:uuid-string() if sem: is not available for iop ML license :)
declare function generate-uuid-v4 (
) as xs:string
{
    let $x := fn:concat (xdmp:integer-to-hex(xdmp:random()), xdmp:integer-to-hex(xdmp:random()))
    return 
    string-join
    (
        (
        fn:substring ($x, 1, 8), fn:substring ($x, 9, 4),
        fn:substring ($x, 13, 4), fn:substring ($x, 17, 4), fn:substring ($x, 21, 14)
        ), 
        '-'
    )
        
};

(: Generate Etag :)
declare function generate-etag (
) as xs:string?
{
    let $x := fn:concat (xdmp:integer-to-hex(xdmp:random()), xdmp:integer-to-hex(xdmp:random()))
    return fn:substring ($x, 1, 18)
   
};

(: ------------------------------------------------------ :)

declare function current-time (
) as xs:string
{
    fn:substring-before(fn:string(fn:current-dateTime()), '+')
};



(: get POST/PUT request body :)

declare function get-xml-body (
) as element()
{
	get-body ("xml")
};

declare private function get-body (
	$type as xs:string
) as node()
{
    try {
        let $xml := xdmp:get-request-body ($type)
        let $node as node()? := ($xml/(element(), $xml/binary(), $xml/text()))[1]
        return
        if (fn:empty ($node))
        then re:throw-xml-error ('HTTP-EMPTYBODY', 400, "Empty body", empty-body ("Expected XML body is empty"))
        else $node
    } catch ($e) {
        re:throw-xml-error ('HTTP-MALXMLBODY', 400, "Malformed body", malformed-body ($e))
    }
};

declare private function empty-body (
	$msg as xs:string
) as element(e:empty-body)
{
	<e:empty-body>
		<e:message>{ $msg }</e:message>   
	</e:empty-body>
};

declare private function malformed-body (
	$error as element(error:error)
) as element(e:malformed-body)
{
	let $msg :=
		if ($error)
		then $error/error:message/fn:string()
		else "Unknown error occurred"

	return
	<e:malformed-body>
		<e:message>{ $msg }</e:message>
	</e:malformed-body>
};



