xquery version '1.0-ml';

module namespace uris="urn:overstory:modules:data-mesh:handlers:lib:records";

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "constants.xqy";
import module namespace rconst="urn:overstory:rest:modules:constants" at "../../rest/lib-rest/constants.xqy";
import module namespace s="urn:overstory:modules:data-mesh:handlers:lib:semantic" at "semantic.xqy";
import module namespace rdfa="urn:overstory:rdf:rdf-ttl" at "rdfa-ttl.xqy";
import module namespace re="urn:overstory:rest:modules:rest:errors" at "../../rest/lib-rest/errors.xqy";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
import module namespace mem = "http://xqdev.com/in-mem-update" at "/MarkLogic/appservices/utils/in-mem-update.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

import module namespace search="urn:overstory:modules:data-mesh:handlers:lib:search" at "lib-search.xqy";

declare namespace e = "http://ns.overstory.co.uk/namespaces/error";
declare namespace error = "http://marklogic.com/xdmp/error";
declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";
declare namespace oss = "http://ns.overstory.co.uk/namespaces/search";
declare namespace atom = "http://www.w3.org/2005/Atom";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace ost = "http://rdf.overstory.co.uk/rdf/terms/";

declare option xdmp:output "indent=yes";

(: ---------------------------------------------------------- :)
(: POST-record.xqy / PUT-record.xqy :)
(: ---------------------------------------------------------- :)

declare function doc-uri-from-short-resource-uri (
	$uri as xs:string
) as xs:string
{
	fn:concat (
		"/mesh/records",
		if (fn:starts-with ($uri, "/")) then "" else "/",
		$uri, ".xml"
	)
};

declare function document-find-by-uri (
	$uri as xs:string
) as document-node()?
{
	cts:search (fn:collection($const:RECORD-COLLECTION), cts:element-value-query (xs:QName ("osc:uri"), $uri))
};

declare function build-document (
    $doc as node(),
    $extracted-triples,
    $created-date as xs:dateTime?
) as node()
{
    let $current-date := fn:current-dateTime()
    let $created-date := if (fn:exists($created-date)) then <osc:created property='ost:created'>{$created-date}</osc:created> else (<osc:created property='ost:created'>{$current-date}</osc:created>)
    let $updated-date := <osc:last-updated property='ost:updated'>{$current-date}</osc:last-updated>
    let $etag := <osc:etag property='ost:etag'>"{build-etag (xs:string ($current-date))}"</osc:etag>
    let $sem-triples := <sem:triples>{$extracted-triples}</sem:triples>
    let $extra-triples := if ($doc/*/osc:extra-triples) then ($doc/*/osc:extra-triples) else (<osc:extra-triples type='rdfa'/>)
    let $root := fn:root($doc)
    return
        element {node-name ($doc)}
        {
            $doc/@*,
            $doc/*[not(self::sem:triples) and not(self::osc:extra-triples) and not(self::osc:created) and not(self::osc:last-updated) and not(self::osc:etag)],
            $created-date,
            $updated-date,
            $etag,
            $extra-triples,
            $sem-triples
        }
};


declare function extract-triples (
    $doc as node()
) (: todo: what's the return type for extracted triples? :)
{
	let $identifier := $doc//@about
    let $ttl := rdfa:rdfa-to-ttl ($doc, $identifier)
    let $triples := sem:rdf-parse ($ttl, "turtle")
    return $triples
};

declare function get-created-date-for-record (
	$uri as xs:string
) as xs:dateTime?
{
	let $record := document-find-by-uri ($uri)
	let $created-date := $record//osc:created/string()
	return xs:dateTime($created-date)
};

declare function collections-for-record (
    $inc-doc as node(),
    $triples,
    $uri as xs:string
) as xs:string*
{
    let $subject := fn:concat('<',$uri,'>')
    let $sparql := fn:concat('PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
                    SELECT ?o
                    WHERE { ',$subject,' rdf:type ?o .}')
    let $result := sem:query-results-serialize (sem:sparql-triples ($sparql, $triples))
    return ($result//sparql:result/sparql:binding/sparql:uri/string(), $const:RECORD-COLLECTION)

};

declare function load-record (
    $doc,
    $uri as xs:string,
    $collections as xs:string*
) as empty-sequence()
{
    xdmp:document-insert (doc-uri-from-short-resource-uri($uri), $doc, xdmp:default-permissions(), $collections)
};

declare function validate-incoming-PUT-identifiers (
	$incoming-uri as xs:string?,
	$osc-uri as xs:string?,
	$about-uri as xs:string?
) as element(e:errors)?
{
	if (fn:empty ($osc-uri))
    then (
    	<e:errors>
            <e:missing-identifier>
                <e:message>osc:uri element value is missing</e:message>
            </e:missing-identifier>
        </e:errors>
    )
    else if (fn:empty ($about-uri))
    then (
    	<e:errors>
            <e:missing-identifier>
                <e:message>Identifier in @about attribute is missing</e:message>
            </e:missing-identifier>
        </e:errors>
    )
    else if ($osc-uri != $about-uri)
    then (
    	<e:errors>
            <e:identifier-mismatch>
                <e:message>Identifier in osc:uri element and @about do not match</e:message>
                <e:osc-uri>{$osc-uri}</e:osc-uri>
                <e:about-uri>{$about-uri}</e:about-uri>
            </e:identifier-mismatch>
        </e:errors>
    )
    else if ($osc-uri != $incoming-uri or $about-uri != $incoming-uri)
    then (
        <e:errors>
            <e:identifier-mismatch>
                <e:message>Request identifier do not match identifier in the xml body</e:message>
                <e:request-uri>{$incoming-uri}</e:request-uri>
                <e:osc-uri>{$osc-uri}</e:osc-uri>
                <e:about-uri>{$about-uri}</e:about-uri>
            </e:identifier-mismatch>
        </e:errors>
    )
    else ()
};

declare function record-exists (
	$incoming-uri as xs:string
) as xs:boolean
{
	fn:exists ( document-find-by-uri ($incoming-uri))
};

declare function validate-incoming-POST-identifiers (
	$osc-uri as xs:string?,
	$about-uri as xs:string?
) as element(e:bad-request)?
{
	if (fn:empty ($osc-uri))
    then (
        <e:bad-request>
            <e:missing-uri>osc:uri element value is missing</e:missing-uri>
        </e:bad-request>
    )
    else if (fn:empty ($about-uri))
    then (
        <e:bad-request>
            <e:missing-uri>Identifier in @about is missing</e:missing-uri>
        </e:bad-request>
    )
    else if ($osc-uri != $about-uri)
    then (
        <e:bad-request>
            <e:uri-mismatch>Identifier in osc:uri element and @about do not match</e:uri-mismatch>
        </e:bad-request>
    )
    else ()
};

(:declare function validate-incoming-POST-identifiers (
	$osc-uri as xs:string?,
	$about-uri as xs:string?
) as element(e:errors)?
{
	if (fn:exists($osc-uri) or fn:exists($about-uri))
    then (
    	<e:errors>
	        <e:malformed-body>
	            <e:message>XML Body on POST request should not contain identifiers in @about and osc:uri</e:message>
	            {
	            if (fn:exists($osc-uri)) then <e:osc-uri>{$osc-uri}</e:osc-uri> else(),
	            if (fn:exists($about-uri)) then <e:about-uri>{$about-uri}</e:about-uri> else()
	            }
	        </e:malformed-body>
        </e:errors>
    )
    else ()
};:)

declare function validate-incoming-etag (
	$incoming-etag as xs:string?,
	$record-etag as xs:string
) as xs:boolean?
{
	fn:exists ($incoming-etag) and ($incoming-etag = $record-etag)
};

declare function etag-from-record-uri (
	$uri as xs:string
) as xs:string?
{
	let $record := document-find-by-uri ($uri)
	let $etag := $record//osc:etag/string()
	return $etag
};

declare function etag-for-record (
	$record as document-node()
) as xs:string
{
	let $etag := $record//osc:etag/string()
	return $etag
};

declare function build-etag (
	$etag-template as xs:string
) as xs:string
{
	fn:translate ($etag-template, "+:.T-", "")
};

declare function etag-conflict (
	$incoming-uri as xs:string?,
	$incoming-etag as xs:string?,
	$record-etag as xs:string?,
	$validate-etag as xs:boolean?,
	$record-exists as xs:boolean
) as element(e:errors)?
{
	xdmp:log ("etag-conflict"),
	if ($record-exists and fn:not ($validate-etag))
	then
		<e:errors>{
			if (fn:empty ($incoming-etag))
			then
				<e:missing-etag>
					<e:message>Missing request ETag to modify {$incoming-uri}</e:message>
					<e:current-etag>{$record-etag}</e:current-etag>
					<e:uri>{$incoming-uri}</e:uri>
				</e:missing-etag>
			else
				<e:etag-mismatch>
					<e:message>Given ETag value does not match current resource ETag</e:message>
                	<e:given-etag>{$incoming-etag}</e:given-etag>
                	<e:current-etag>{$record-etag}</e:current-etag>
                </e:etag-mismatch>
		}</e:errors>
	else ()
};

(: --------------------------------------- :)
(: RECORD VALIDATION :)
(: --------------------------------------- :)

declare function validate-record (
	$doc as element(),
	$triples,
	$typeof as xs:string*
) as element(e:errors)?
{
	let $validate-properties := validate-required-properties ($triples, $typeof)
	let $validate-elements := validate-required-elements ($doc, $typeof)
	let $validate-schema := validate-schema-elements ($doc, $typeof)
	return
		if ( (fn:not (fn:empty ($validate-properties))) or (fn:not (fn:empty ($validate-elements))) or (fn:not (fn:empty ($validate-schema))))
		then <e:errors>{$validate-properties, $validate-elements, $validate-schema}</e:errors>
		else ()
};

declare function validate-schema-elements (
	$doc as element(),
	$typeof as xs:string*
)
{
	let $schema-errors :=
		for $rdf-type in $typeof
		let $SPARQL := fn:concat (fn:string-join (search:build-prefix-list (), " "), (" "), fn:replace($const:SCHEMA-VALIDATION-SPARQL-TEMPLATE, '&apos;incoming-rdf-type&apos;', $rdf-type))
		let $result-map := sem:sparql ($SPARQL)
		return
			for $result in $result-map
			return
				let $element-name := map:get ($result, "elementName")
				let $element-ns := map:get ($result, "elementNs")
				return
					for $element in $doc//*[namespace-uri() = $element-ns][local-name() = fn:substring-after ($element-name, ":") ]
					return
						try {
							let $_ := validate { document { $element } }
							return ()
						} catch ($e) {
							<e:schema-validation>{
								if ($e/error:code = 'XDMP-VALIDATEUNEXPECTED')
								then (
									<e:message>Schema Validation failed for element {$element-name}</e:message>,
									<e:error>{$e/error:format-string/string()}</e:error>
								)
								else if ($e/error:code ='XDMP-VALIDATENODECL')
								then (
									<e:message>Schema could not be found to validate element {$element-name}</e:message>,
									<e:error>{$e/error:format-string/string()}</e:error>
								)
								else (
									<e:message>Schema Validation error for element {$element-name}</e:message>,
									<e:error>{$e/error:format-string/string()}</e:error>
								)
							}</e:schema-validation>
						}
	return
		if (fn:empty ($schema-errors)) then ()
		else <e:errors>{$schema-errors}</e:errors>


};

declare function validate-required-elements (
	$doc as element(),
	$typeof as xs:string*
) as element(e:validation-failed)*
{
	(: for each typeof in the document get a list of required elements :)
	for $rdf-type in $typeof
	let $SPARQL := fn:concat (fn:string-join (search:build-prefix-list (), " "), (" "), fn:replace($const:REQUIRED-ELEMENTS-FROM-RDF-TYPE-SPARQL-TEMPLATE, '&apos;incoming-rdf-type&apos;', $rdf-type))
	let $result-map := sem:sparql ($SPARQL)
	return
		(: for each result harvest information about a validation :)
		for $result in $result-map
		return
			let $element-name := map:get ($result, "elementName")
			let $element-ns := map:get ($result, "elementNs")

			let $element-type := map:get ($result, "elementType")
			let $min-occurs := (map:get ($result, "minOccurs"), ("1"))[1]
			let $max-occurs := (map:get ($result, "maxOccurs"), ("1"))[1]
			let $prop-def := map:get ($result, "propDef")
			return
				(: if there is no property-def then the check is only for required element on the root level :)
				if (fn:empty ($prop-def))
				then
					(: find elements based on element-ns and element-name :)
					let $elements-validated := ($doc//*[namespace-uri() = $element-ns][local-name() = fn:substring-after ($element-name, ":") ])
					(: count how many there are :)
					let $elements-occurs := fn:count ($elements-validated)
					(: validate each element string - castable as element-type :)
					let $validate-element-type := if (fn:empty ($element-type)) then () else validate-element-type ($elements-validated, $element-name, $element-type, $rdf-type)
					(: validate each element - min/max occurs :)
					let $validate-element-occurs := validate-element-occurs ($elements-occurs, $min-occurs, $max-occurs, $element-name, $rdf-type, ())
					return
						($validate-element-type, $validate-element-occurs)
				else
					let $SPARQL := fn:concat (fn:string-join (search:build-prefix-list (), " "), (" "), "SELECT ?propName ?propType { <" || $prop-def || "> ost:propertyName ?propName  . OPTIONAL { <" || $prop-def || "> ost:propertyType ?propType } }")
					let $result-map := sem:sparql ($SPARQL)
					let $prop-name := map:get ($result-map, "propName")
					let $elements-validated := $doc//*[namespace-uri() = $element-ns][local-name() = fn:substring-after ($element-name, ":")][./@property][./@property/string() = $prop-name]
					let $elements-occurs := fn:count ($elements-validated)
					let $validate-element-type := if (fn:empty ($element-type)) then () else validate-element-type ($elements-validated, $element-name, $element-type, $rdf-type)
					let $validate-element-occurs := validate-element-occurs ($elements-occurs, $min-occurs, $max-occurs, $element-name, $rdf-type, $prop-name)
					return
						($validate-element-type, $validate-element-occurs)

};

declare function validate-element-occurs (
	$element-occurs as xs:int,
	$min-occurs as xs:string,
	$max-occurs as xs:string,
	$element-name as xs:string,
	$rdf-type as xs:string,
	$property-name as xs:string?
) as element(e:validation-failed)*
{
	if ($element-occurs < xs:int($min-occurs))
	then
		<e:validation-failed>
			<e:message>Validation for rdf type '{$rdf-type}' document failed, minimal occurs not met for the element '{$element-name}' {if (fn:empty($property-name)) then () else "with property '" || $property-name ||"'"}.</e:message>
			<e:element-name>{$element-name}</e:element-name>
			<e:minimal-occurs>{$min-occurs}</e:minimal-occurs>
		</e:validation-failed>
	else if ($max-occurs = "*")
	then ()
	else
		if ($element-occurs > xs:int($max-occurs))
		then
			<e:validation-failed>
				<e:message>Validation for rdf type '{$rdf-type}' document failed, maximal occurs not met for the element '{$element-name}' with property '{$property-name}'.</e:message>
				<e:element-name>{$element-name}</e:element-name>
				<e:maximum-occurs>{$max-occurs}</e:maximum-occurs>
			</e:validation-failed>
		else()
};

declare function validate-element-type (
	$elements-validated as element()*,
	$element-name as xs:string,
	$element-type as xs:string,
	$rdf-type as xs:string
) as element(e:validation-failed)*
{
	for $element in $elements-validated
	let $element-value := $element/string()
	let $castable := xdmp:castable-as ("http://www.w3.org/2001/XMLSchema", "int"(:fn:substring-after ($element-type, ":"):), $element-value)
	return
		if ($castable = fn:true())
		then ()
		else
			<e:validation-failed>
				<e:message>Validation for rdf type '{$rdf-type}' document failed, required type for element '{$element-name}' is '{$element-type}', provided value for that element was '{$element-value}'.</e:message>
				<e:element-name>{$element-name}</e:element-name>
				<e:required-type>{$element-type}</e:required-type>
				<e:element-value>{$element-value}</e:element-value>
			</e:validation-failed>
};

declare function validate-required-properties (
	$triples,
	$typeof as xs:string*
) as element(e:validation-failed)*
{
	for $rdf-type in $typeof
	let $SPARQL := fn:concat (fn:string-join (search:build-prefix-list (), " "), (" "), fn:replace($const:REQUIRED-PROPERTIES-FROM-RDF-TYPE-SPARQL-TEMPLATE, '&apos;incoming-rdf-type&apos;', $rdf-type))
	let $result-map := sem:sparql ($SPARQL)
	return
		for $result in $result-map
		return
			let $prop-name := map:get ($result, "propName")
			let $prop-type := map:get ($result, "propType")
			let $min-occurs := (map:get ($result, "minOccurs"), ("1"))[1]
			let $max-occurs := (map:get ($result, "maxOccurs"), ("1"))[1]
			let $SPARQL := fn:concat (fn:string-join (search:build-prefix-list (), " "), (" "), "SELECT ?o WHERE { ?s "  || $prop-name || " ?o }")
			let $result-map := sem:sparql-triples ($SPARQL, $triples)
			let $prop-occurs := fn:count ($result-map)
			let $validate-property-type := if (fn:empty ($prop-type)) then () else validate-property-type ($result-map, $prop-type, $rdf-type, $prop-name)
			let $validate-property-occurs := validate-property-occurs ($prop-name, xs:int($prop-occurs), $min-occurs, $max-occurs, $rdf-type)
			return ( $validate-property-occurs, $validate-property-type )
};

declare function validate-property-type (
	$result-map,
	$prop-type as xs:string,
	$rdf-type as xs:string,
	$prop-name as xs:string
) as element(e:validation-failed)*
{
	for $result in $result-map
	let $prop-value := map:get ($result, "o")
	let $castable := xdmp:castable-as ("http://www.w3.org/2001/XMLSchema", fn:substring-after ($prop-type, ":"), $prop-value)
	return
		if ($castable = fn:true())
		then ()
		else
			<e:validation-failed>
				<e:message>Validation for rdf type '{$rdf-type}' document failed, required type for property '{$prop-name}' is '{$prop-type}', provided value for that property was '{$prop-value}'.</e:message>
				<e:property-name>{$prop-name}</e:property-name>
				<e:required-type>{$prop-type}</e:required-type>
				<e:property-value>{$prop-value}</e:property-value>
			</e:validation-failed>
};

declare function validate-property-occurs (
	$prop-name as xs:string,
	$prop-occurs as xs:int,
	$min-occurs as xs:string,
	$max-occurs as xs:string,
	$rdf-type as xs:string
) as element(e:validation-failed)*
{
	if ($prop-occurs < xs:int($min-occurs))
	then
		<e:validation-failed>
			<e:message>Validation for rdf type '{$rdf-type}' document failed, minimal occurs not met for the property '{$prop-name}'.</e:message>
			<e:property-name>{$prop-name}</e:property-name>
			<e:minimal-occurs>{$min-occurs}</e:minimal-occurs>
		</e:validation-failed>
	else if ($max-occurs = "*")
	then ()
	else
		if ($prop-occurs	 > xs:int($max-occurs))
		then
			<e:validation-failed>
				<e:message>Validation for rdf type '{$rdf-type}' document failed, maximal occurs not met for the property '{$prop-name}'.</e:message>
				<e:property-name>{$prop-name}</e:property-name>
				<e:maximum-occurs>{$max-occurs}</e:maximum-occurs>
			</e:validation-failed>
		else()
};

declare function extract-predefined-rdf-types (
	$incoming-doc,
	$record-rdf-type
) as xs:string*
{
	for $rdf-type in fn:tokenize ($record-rdf-type, ' ')
	let $SPARQL := fn:concat (fn:string-join (search:build-prefix-list (), " "), (" "), fn:replace($const:PREDEFINED-RDF-TYPES-SPARQL-TEMPLATE, '&apos;incoming-rdf-type&apos;', $rdf-type))
	let $result-map := sem:sparql ($SPARQL)
	return
		for $result in $result-map
		let $predefined-type := map:get ($result, 'rdfType')
		return
			if (fn:contains ($record-rdf-type, $predefined-type))
			then ()
			else $predefined-type
};

declare function inject-predefined-rdf-types (
	$incoming-doc,
	$predefined-types as xs:string*
) as element()
{
	let $current-types := $incoming-doc/@typeof/string()
	let $prefix-map := prefix-map()
	let $new-types :=
		for $type in $predefined-types
		let $curied :=
			for $key in map:keys ($prefix-map)
            where fn:starts-with ($type, $key)
            return fn:concat (map:get ($prefix-map, $key), ':', fn:substring-after($type, $key))
        return
        	if (fn:empty ($curied)) then $type else $curied
	let $final-types := fn:concat( fn:string-join ($new-types, ' '), ' ', $current-types)
		return
			element {node-name ($incoming-doc/self::*)}
	        {
				$incoming-doc/@*[name() != 'typeof'],
				attribute {'typeof'} {$final-types},
				$incoming-doc/*
	        }
};

(:declare function extract-predefined-properties (
	$incoming-doc,
	$record-rdf-type
) as element(predefined-properties)
{
	<predefined-properties>{
		for $rdf-type in fn:tokenize ($record-rdf-type, ' ')
		let $SPARQL := fn:concat (fn:string-join (search:build-prefix-list (), " "), (" "), fn:replace($const:RECORD-DEFINITION-RECORD-URI-FOR-INCOMING-TYPE, '&apos;incoming-rdf-type&apos;', $rdf-type))
		let $result-map := sem:sparql ($SPARQL)
		return
			let $record-definition := fetch-record-with-short-resource-uri (map:get ($result-map, 'uri'))
			let $predefined-properties := $record-definition/*/osc:predefined-properties/*
			return $predefined-properties
	}</predefined-properties>
};
:)

declare function extract-predefined-properties (
	$incoming-doc,
	$record-rdf-type
)
{
	<predefined-properties>{
	for $rdf-type in fn:tokenize ($record-rdf-type, ' ') [1]
	let $SPARQL := fn:concat (fn:string-join (search:build-prefix-list (), " "), (" "), fn:replace($const:PREDEFINED-PROPERTIES-SPARQL-TEMPLATE, '&apos;incoming-rdf-type&apos;', $rdf-type))
	let $result-map := sem:sparql ($SPARQL)
	return
		xdmp:unquote(map:get ($result-map, 'predefinedProp'), "", ("repair-full"))
	}</predefined-properties>
};

declare function inject-predefined-properties (
	$incoming-doc,
	$predefined-properties as element(predefined-properties)
)
{
	element {node-name ($incoming-doc/self::*)}
    {
		$incoming-doc/@*,
		$incoming-doc/*[not(self::osc:properties)],
		<osc:properties>{$incoming-doc/osc:properties/*, $predefined-properties/*}</osc:properties>
    }
};

(: ---------------------------------------------------------- :)
(: GET-record.xqy :)
(: ---------------------------------------------------------- :)

declare function fetch-record-with-short-resource-uri (
	$short-resource-uri as xs:string
) as document-node()?
{
	fetch-record (doc-uri-from-short-resource-uri ($short-resource-uri))
};

declare function fetch-record (
	$doc-uri as xs:string
) as document-node()?
{
	fn:doc ($doc-uri)
};

declare function prepare-record-resource (
    $doc as document-node()
) as node()
{
    element {fn:node-name ($doc/*)}
    {
        $doc/*/@*,
        $doc/*/*[not(self::sem:triples) and not(self::osc:extra-triples)]
    }
};

(: ---------------------------------------------------------- :)
(: DELETE-record.xqy :)
(: ---------------------------------------------------------- :)

declare function delete-record-with-short-resource-uri (
	$short-resource-uri as xs:string
) as empty-sequence()
{
	delete-record (doc-uri-from-short-resource-uri ($short-resource-uri))
};

declare function delete-record (
	$doc-uri as xs:string
) as empty-sequence()
{
	if (fn:doc-available ($doc-uri)) then xdmp:document-delete ($doc-uri) else ()
};


(: ---------------------------------------------------------- :)
(: GET-type.xqy :)
(: ---------------------------------------------------------- :)

declare function get-types (
	$search-criteria as element(oss:search-criteria),
	$wants-atom as xs:boolean
) (:as element(atom:feed)? :)
{
    let $type-doc := type-list ($search-criteria/oss:type-sparql)
    let $search-response := build-type-search-response ($type-doc, $search-criteria, $wants-atom)
    return $search-response
};

declare function type-list (
   $type-sparql as xs:string
) as element(osc:types)?
{
    let $prefix-map := prefix-map()
    let $sparql-results := sem:sparql($type-sparql)
    return
        <osc:types>
        {
            for $value in distinct-values(map:get($sparql-results, 'search'))
            return
                <osc:type-entry>
                    <osc:type-uri>{$value}</osc:type-uri>
                    <osc:type-curie>
                    {
                        for $key in map:keys ($prefix-map)
                        where fn:starts-with ($value, $key)
                        return fn:concat (map:get ($prefix-map, $key), ':', fn:substring-after($value, $key))
                    }
                    </osc:type-curie>
                </osc:type-entry>
        }
        </osc:types>
};

declare function build-type-search-response (
    $prefix-doc as node(),
    $search-criteria as element(oss:search-criteria),
    $wants-atom as xs:boolean
) as element()
{
    let $total-hits := fn:count ($prefix-doc//osc:type-entry)
    let $page-size := $search-criteria/oss:ipp
    let $first := $search-criteria/oss:first
    let $last := $search-criteria/oss:last
    return
    if ($wants-atom)
    then
    	build-type-atom-response ($prefix-doc, $search-criteria)
    else
        <oss:result first="{$first}" last="{$last}" page-size="{$page-size}" total-hits="{$total-hits}">
    	{
            for $entry in $prefix-doc//osc:type-entry [$first to $last]
            return
                <osc:type>
                    {
                        $entry/*
                    }
                </osc:type>
    	}
        </oss:result>
};


declare function prefix-map (
) as map:map
{
    let $prefixes := cts:search(collection('http://rdf.overstory.co.uk/rdf/terms/Prefix'), cts:element-value-query( xs:QName("osc:prefix-uri"), '*', ("wildcarded")))
    let $prefix-map := map:map()
    let $build-prefix-map :=
            for $doc in $prefixes
            return map:put($prefix-map, $doc//osc:prefix-uri/string(), $doc//osc:prefix-name/string())
    return $prefix-map
};


(: ---------------------------------------------------------- :)
(: GET-prefix.xqy :)
(: ---------------------------------------------------------- :)

declare function retrieve-prefix-resource (
    $prefix-uri as xs:string
) as document-node()?
{
    document-find-by-uri ($prefix-uri)
};

(: ---------------------------------------------------------- :)
(: PUT-prefix.xqy  :)
(: ---------------------------------------------------------- :)

declare function prefix-exists (
    $prefix-uri as xs:string
) as xs:boolean
{
    fn:exists ( document-find-by-uri ($prefix-uri) )
};

declare function build-prefix-uri (
    $prefix as xs:string
) as xs:string
{
    fn:concat ('urn:overstory.co.uk:id:prefix:',$prefix)
};

declare function build-prefix-document (
    $prefix-identifier as xs:string,
    $prefix-name as xs:string,
    $prefix-uri as xs:string
) as node()
{
    <osc:prefix typeof="ost:Prefix ost:MetaRecord" about="{$prefix-identifier}" prefix="ost: http://rdf.overstory.co.uk/rdf/terms/ foaf: http://xmlns.com/foaf/0.1/ dc: http://purl.org/dc/terms/">
        <osc:uri property="dc:identifier osc:uri">{$prefix-identifier}</osc:uri>
        <osc:prefix-name property="ost:prefixName">{$prefix-name}</osc:prefix-name>
        <osc:prefix-uri property="ost:prefixUri">{$prefix-uri}</osc:prefix-uri>
    </osc:prefix>

};

declare function validate-prefix-uri (
	$prefix-uri as xs:anyURI
) as element(e:errors)?
{
	if (fn:matches ($prefix-uri, "^(https?)://.+$") )
    then ()
    else if (fn:matches ($prefix-uri, "^urn:[a-z0-9()+,\-.:=@;$_!*'%/?#]+$"))
    then ()
    else
    	<e:errors>
			<e:malformed-body>
				<e:message>Prefix uri is incorrect</e:message>
				<e:prefix-uri>{$prefix-uri}</e:prefix-uri>
			</e:malformed-body>
    	</e:errors>
};

(: ---------------------------------------------------------- :)
(: DELETE-prefix.xqy :)
(: ---------------------------------------------------------- :)

declare function delete-prefix (
    $prefix-uri as xs:string
) as empty-sequence()
{
    xdmp:document-delete ( doc-uri-from-short-resource-uri ($prefix-uri) )
};


(: ---------------------------------------------------------- :)
(: PUT-triple.xqy :)
(: ---------------------------------------------------------- :)

declare function check-resource (
    $subject as xs:string
) as xs:boolean
{
    let $sparql := fn:concat("PREFIX ost: <http://rdf.overstory.co.uk/rdf/terms/>
                    SELECT ?s
                    WHERE { ?s ost:uri '",$subject,"' .}")
    let $result := sem:query-results-serialize (sem:sparql ($sparql))
    return fn:exists($result//sparql:results/sparql:result)
};

declare function build-rdfa-triple (
    $predicate as xs:string,
    $object as xs:string,
    $description as xs:string?
) as element()?
{
	let $object-type := check-object-type ($predicate, $object)
	let $rdf-element-map := predicate-element-mapping ($predicate)
	let $element-name := map:get($rdf-element-map, 'elementName')
	let $element-name :=
        if (fn:empty($element-name))
        then
        	if ($object-type = 'property')
            then 'osc:property'
            else if ($object-type = 'resource-ref')
            then 'osc:resource-ref'
            else ()
        else $element-name

	let $element-name-ns-prefix := get-ns-prefix ($element-name)
	let $element-ns := ((if ($element-name-ns-prefix = 'osc') then ($const:OSC-NAMESPACE) else()), map:get($rdf-element-map, 'elementNs'), get-ns-for-prefix ($element-name-ns-prefix))[1]
    let $element-qname := fn:QName ($element-ns, $element-name)

	return
        if ($object-type = 'property')
        then
            if ($description!='')
            then (
                element {$element-qname}
                {
                    attribute {'property'} {$predicate},
                    attribute {'content'} {$object},
                    $description
                }
            ) else (
                element {$element-qname}
                {
                    attribute {'property'} {$predicate},
                    $object
                }
            )
        else if ($object-type = 'resource-ref')
        then
            if ($description!='')
            then (
                element {$element-qname}
                {
                    attribute {'property'} {$predicate},
                    attribute {'resource'} {$object},
                    $description
                }
            ) else (
                element {$element-qname}
                {
                    attribute {'property'} {$predicate},
                    attribute {'resource'} {$object},
                    $object
                }
            )
        else()
};

declare function get-ns-prefix (
	$input as xs:string
) as xs:string
{
	fn:substring-before ($input, ':')
};

declare function get-local-name (
	$input as xs:string
) as xs:string
{
	fn:substring-after ($input, ':')
};

declare function get-ns-for-prefix (
	$prefix-name as xs:string
) as xs:string?
{
	let $prefix-sparql := fn:concat (fn:string-join (search:build-prefix-list (), " "), (" "), fn:replace($const:NS-FROM-PREFIX-SPARQL-TEMPLATE, 'prefix-name', $prefix-name))
	let $result := map:get(sem:sparql($prefix-sparql), "prefixUri")
	return $result
};

declare function predicate-element-mapping (
    $predicate as xs:string
) as sem:binding?
{
    let $mapping-sparql := fn:concat (fn:string-join (search:build-prefix-list (), " "), (" "), fn:replace($const:ELEMENT-MAPPING-SPARQL-TEMPLATE, 'predicate-name', $predicate))
    let $result := sem:sparql($mapping-sparql)
    return $result
};

declare function check-object-type (
	$predicate as xs:string,
    $object as xs:string
) as xs:string
{
    if (fn:matches ($object, "^urn:[a-z0-9()+,\-.:=@;$_!*'%/?#]+$") or $predicate = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' or $predicate = 'rdf:type')
    then ('resource-ref')
    (:else if (fn:matches ($object, "^(https?|ftp|file)://.+$") )
    then ('resource-ref'):)
    else ('property')
};

(: todo: check-?? whats a gd name :)
declare function check-curie (
    $input as xs:string
) as xs:boolean
{
    (: URL :)
    if (fn:matches ($input, "^(https?|ftp|file)://.+$") )
    then (fn:true())
    (: URN :)
    else if (fn:matches ($input, "^urn:[a-z0-9()+,\-.:=@;$_!*'%/?#]+$"))
    then (fn:true())
    (: CURIE :)
    else if (fn:matches ($input, "[A-z]+:[A-z]+$"))
    then (prefix-exists (build-prefix-uri (fn:substring-before ($input, ':'))))
    (: Text :)
    else (fn:true())
};

declare function put-rdfa-triple (
    $uri as xs:string,
    $rdfa-triple as element()
) as empty-sequence()
{
    let $target-doc := document-find-by-uri ($uri)
    let $collections := xdmp:document-get-collections (doc-uri-from-short-resource-uri ($uri))
    let $new-extra-triples :=
        <osc:properties>{
            $target-doc/*/osc:properties/*,
            $rdfa-triple
        }</osc:properties>
    let $new-document := mem:node-replace($target-doc/*/osc:properties, $new-extra-triples)
    let $new-sem-triples := <sem:triples>{extract-triples($new-document)}</sem:triples>
    let $new-document := mem:node-replace($new-document/*/sem:triples, $new-sem-triples)
    return load-record ($new-document, $uri, $collections)
};

(: ---------------------------------------------------------- :)
(:  DELETE-triple.xqy :)
(: ---------------------------------------------------------- :)

declare function triple-exists (
    $subject as xs:string,
    $predicate as xs:string,
    $object as xs:string
) as xs:boolean
{
    let $sparql := build-triple-check-sparql ($subject, $predicate, $object)
    return sem:sparql($sparql)
};

declare function build-triple-check-sparql (
    $subject as xs:string,
    $predicate as xs:string,
    $object as xs:string
)
{
    let $subject := search:build-sparql-value ($subject)
    let $predicate := search:build-sparql-value ($predicate)
    let $object := search:build-sparql-value ($object)
    return
    (
        fn:concat(fn:string-join (search:build-prefix-list(), " "), (" "),
        fn:concat('ASK { ', $subject, ' ', $predicate, ' ', $object, ' }'))
    )
};

declare function delete-triple (
    $subject as xs:string,
    $predicate as xs:string,
    $object as xs:string
)
{
    let $document-uri := doc-uri-from-short-resource-uri ($subject)
    let $target-doc := document-find-by-uri ($subject)
    let $collections := xdmp:document-get-collections ($document-uri)
    let $object-type := check-object-type ($predicate, $object)
    let $new-document :=
        if ($object-type = 'property')
        then mem:node-delete ($target-doc//*[./string()=$object or @content=$object][1])
        else mem:node-delete ($target-doc//*[@resource=$object][1])
    let $new-sem-triples := <sem:triples>{extract-triples($new-document)}</sem:triples>
    let $new-document := mem:node-replace($new-document/*/sem:triples, $new-sem-triples)
    return load-record ($new-document, $subject, $collections)
};

declare function validate-triple-params (
	$subject as xs:string?,
	$predicate as xs:string?,
	$object as xs:string?
) as element(e:errors)?
{
	if (fn:empty($subject) or fn:empty($predicate) or fn:empty($object))
	then
		<e:errors>
			<e:missing-parameter>
                        <e:message>Parameter is empty</e:message>
                        <e:parameter-name>
                        {if (fn:empty($subject)) then 'subject' else if (fn:empty($predicate)) then 'predicate' else if (fn:empty($object)) then 'object' else() }
                        </e:parameter-name>
            </e:missing-parameter>
		</e:errors>
	else if (
	$predicate = 'ost:etag' or $predicate = $const:OST-FULL-URI || 'etag'
	or $predicate = 'ost:created' or $predicate = $const:OST-FULL-URI || 'created'
	or $predicate = 'ost:updated' or $predicate = $const:OST-FULL-URI || 'updated'
	or $predicate = 'ost:uri' or $predicate = $const:OST-FULL-URI || 'ost:uri'
	)
	then
		<e:errors>
			<e:incorrect-parameter>
                        <e:message>Parameter is incorrect. Triple with the specified predicate could not be changed.</e:message>
                        <e:parameter-name>predicate</e:parameter-name>
                        <e:parameter-value>{$predicate}</e:parameter-value>
            </e:incorrect-parameter>
		</e:errors>
	else ()
};


(: ---------------------------------------------------------- :)
(:  Get XML Request Body :)
(: ---------------------------------------------------------- :)

declare function get-xml-body (
) as element()
{
	get-body ("xml")
};

declare function get-text-body (
) as text()
{
	get-body ("text")
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
        then re:throw-xml-error ('HTTP-EMPTYBODY', 400, "Empty body", empty-body ("Expected POST body is empty"))
        else $node
    } catch ($e) {
        re:throw-xml-error ('HTTP-MALXMLBODY', 400, "Malformed body", malformed-body ($e))
    }
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

declare private function empty-body (
	$msg as xs:string
) as element(e:empty-body)
{
	<e:empty-body>
		<e:message>{ $msg }</e:message>
	</e:empty-body>
};



(: ---------------------------------------------------------- :)
(: ---------------------------------------------------------- :)
(: ----------------------- ARCHIVE -------------------------- :)
(: ---------------------------------------------------------- :)
(: ---------------------------------------------------------- :)

(: ---------------------------------------------------------- :)
(: PUT-type.xqy - OBSOLETE :)
(: ---------------------------------------------------------- :)

declare function type-exists (
    $type as xs:string
) as xs:boolean
{
    fn:boolean( cts:search (
        fn:collection ($const:RDF-TYPE-COLLECTION)/osc:types/osc:type, cts:element-value-query(
            xs:QName("osc:curie"), $type)) )

};

declare function update-type (
    $incoming-doc as node(),
    $type as xs:string
)
{
    xdmp:node-replace(
    cts:search(
    fn:collection ($const:RDF-TYPE-COLLECTION)/osc:types/osc:type, cts:element-value-query(
          xs:QName("osc:curie"),
          $type))
    , $incoming-doc)
};

declare function add-type (
    $incoming-doc as node()
)
{
    xdmp:node-insert-child(
    cts:search(
    fn:collection ($const:RDF-TYPE-COLLECTION)/osc:types, () )
    , $incoming-doc)
};

(: ---------------------------------------------------------- :)
(: GET-prefix-list.xqy - build atom response - OBSOLETE :)
(: ---------------------------------------------------------- :)

declare function build-prefix-atom-response (
    $prefix-doc as document-node(),
    $search-criteria as element(oss:search-criteria)
) as element(atom:feed)
{
    let $total-hits := fn:count($prefix-doc//osc:prefix-map-entry)
    let $current-first-item := $search-criteria/oss:first-item
    let $current-page := $search-criteria/oss:page
    let $ipp := $search-criteria/oss:ipp

    (: todo: rethink this? :)
    let $from := xs:int($current-page * $ipp - $ipp + 1)
    let $to := xs:int($from + $ipp - 1)

    return
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:osc="http://ns.overstory.co.uk/namespaces/datamesh/content" xmlns:oss="http://ns.overstory.co.uk/namespaces/search">
            <id>/rdf/prefix</id>
            <title type="text">Search feed</title>
            <link href="{$search-criteria/oss:request-url}" rel="self"/>
            {
                search:build-prev-link($search-criteria),
                search:build-next-link($search-criteria, $total-hits),
                <updated>{fn:current-dateTime()}</updated>,
                $search-criteria,
                for $value at $position in $prefix-doc//osc:prefix-map-entry [$from to $to]
                return
                    <entry>
                        <id>{$value/osc:prefix-name/string()}</id>
                        <link href="/rdf/prefix/{$value/osc:prefix-name/string()}" rel="self"/>
                        {$value}
                    </entry>
            }
        </feed>
};

(: ---------------------------------------------------------- :)
(: GET-type.xqy - build atom response - OBSOLETE :)
(: ---------------------------------------------------------- :)

declare function build-type-atom-response (
    $type-doc as node(),
    $search-criteria as element(oss:search-criteria)
) as element(atom:feed)
{
    let $total-hits := fn:count($type-doc//osc:type-entry)
    let $current-first-item := $search-criteria/oss:first-item
    let $current-page := $search-criteria/oss:page
    let $ipp := $search-criteria/oss:ipp

    (: todo: rethink this? :)
    let $from := xs:int($current-page * $ipp - $ipp + 1)
    let $to := xs:int($from + $ipp - 1)

    return
        <feed xmlns="http://www.w3.org/2005/Atom" xmlns:osc="http://ns.overstory.co.uk/namespaces/datamesh/content" xmlns:oss="http://ns.overstory.co.uk/namespaces/search">
            <id>/rdf/record/type</id>
            <title type="text">Search feed</title>
            <link href="{$search-criteria/oss:request-url}" rel="self" type="{$rconst:MEDIA-TYPE-ATOM_XML}"/>
            {
                search:build-prev-link($search-criteria),
                search:build-next-link($search-criteria, $total-hits),
                $search-criteria
            }
            <updated>{fn:current-dateTime()}</updated>
            {
                for $value at $position in $type-doc//osc:type-entry [$from to $to]
                return
                    <entry>
                        <id>{$value/osc:type-curie/string()}</id>
                        <updated>fn:current-dateTime()</updated>
                        {$value/*}
                    </entry>
            }
        </feed>
};

(:declare function update-prefix-OBSOLETE (
    $uri as xs:anyURI,
    $prefix as xs:string
)
{
    xdmp:node-replace(
    cts:search(
    fn:collection ($const:RDF-PREFIX-COLLECTION)/osc:prefixes/osc:prefix-map-entry, cts:element-value-query(
          xs:QName("osc:prefix-name"),
          $prefix)),
    build-prefix-resource($uri,$prefix)),
    PUT-prefix-response($prefix)
};

declare function add-prefix-OBSOLETE (
    $uri as xs:anyURI,
    $prefix as xs:string
)
{
    xdmp:node-insert-child(
    cts:search(
    fn:collection ($const:RDF-PREFIX-COLLECTION)/osc:prefixes, () ),
    build-prefix-resource($uri,$prefix)),
    PUT-prefix-response($prefix)
};

declare function build-prefix-resource-OBSOLETE (
    $uri as xs:anyURI,
    $prefix as xs:string
) as element(osc:prefix-map-entry)?
{
    <osc:prefix-map-entry>
        <osc:prefix-name>{$prefix}</osc:prefix-name>
        <osc:prefix-uri>{$uri}</osc:prefix-uri>
    </osc:prefix-map-entry>
};:)
