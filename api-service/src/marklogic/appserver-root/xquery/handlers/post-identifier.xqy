xquery version "1.0-ml";

import module namespace lib="urn:overstory:modules:data-mesh:handlers:lib:identifier" at "lib/lib-identifier.xqy";

declare namespace i = "http://ns.overstory.co.uk/namespaces/meta/id";

(: 
Incoming doc example:

<i:annotation xmlns:i="http://ns.overstory.co.uk/resources/meta/id">
        <i:id>12345678</i:id>
        <i:content-type>image/jpg</i:content-type>
</i:annotation>
:)
(:

?template=article-{doi:10.1088/23414/21344/24/4}

?template=article-{doi:10.1088/23414/21344/24/4}.blob

?template=resource-{now}.blob

?template=manifestation:filestore-{}-{file: files/njp9_2_025008.pdf}

:)

(: POST Request body :)
declare variable $incoming-doc as element() := lib:get-xml-body();
(: double check that the incoming doc has a root <i:annotation> :)
declare variable $check-incoming-doc as xs:boolean := lib:check-identifier-annotation($incoming-doc);

declare variable $template as xs:string? := xdmp:get-request-field("template", ());

declare variable $etag := lib:generate-etag();

declare variable $identifier := lib:identifier-from-template ($template);

(: identifier exists? :)
declare variable $identifier-exists as xs:boolean := lib:identifier-exists ($identifier);


if (fn:not ($identifier-exists))
then (
    let $system := lib:identifier-system-info($etag)
    let $annotations := if ($check-incoming-doc) then ($incoming-doc) else (<i:annotation xmlns:i="http://ns.overstory.co.uk/namespaces/meta/id"/>)
    let $identifier-xml := lib:identifier-info($system, $annotations)
    let $_ := xdmp:set-response-code (201, "Created")
    let $_ := xdmp:add-response-header ("Content-Type", 'application/vnd.overstory.id+xml')
	let $_ := xdmp:add-response-header ("Location", $identifier)
	let $_ := xdmp:add-response-header ("Etag", $etag)
	return 
    (
    lib:store-identifier-doc($identifier-xml, $identifier)
    )
)
else if ( $identifier-exists )
then 
(
    let $_ := xdmp:set-response-code (400, "Bad Request")
    let $_ := xdmp:add-response-header ("Content-Type", 'application/vnd.overstory.error+xml')
    return
    <e:errors xmlns:e="http://ns.overstory.co.uk/namespaces/resources/error">
        <e:message>Cannot create unique URN from provided template as the identifier already exists.</e:message>
        <e:bad-identifier>{$identifier}</e:bad-identifier>
    </e:errors>
)
else ()






