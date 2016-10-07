xquery version '1.0-ml';

import module namespace r="urn:overstory:modules:data-mesh:handlers:lib:records" at "../lib/lib-records.xqy";
import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "../lib/constants.xqy";

declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";
declare namespace e = "http://ns.overstory.co.uk/namespaces/error";

declare option xdmp:output "indent=yes";

declare variable $incoming-uri as xs:string := xdmp:get-request-field ("uri", ());
declare variable $incoming-etag as xs:string? := xdmp:get-request-header ("etag", ());
declare variable $incoming-doc as element() := r:get-xml-body();
declare variable $validate-flag as xs:string := xdmp:get-request-field ("validate", "true");

(:let $record-rdf-type := $incoming-doc/@typeof
let $extracted-triples := r:extract-triples ($incoming-doc)
let $validate-record := r:validate-record ($incoming-doc, $extracted-triples, tokenize($record-rdf-type, ' '))
return $validate-record
:)
let $osc-uri := $incoming-doc/osc:uri/string()
let $about-uri := $incoming-doc/@about/string()
let $bad-request := r:validate-incoming-PUT-identifiers ($incoming-uri,$osc-uri,$about-uri)
return 
	if (fn:not (fn:empty ($bad-request)))
	then (
		$bad-request,
		xdmp:set-response-content-type ($const:CT-ERROR-XML), 
        xdmp:set-response-code (400, "Bad Request")
	)
	else 
		let $record-etag as xs:string? := r:etag-from-record-uri ($incoming-uri)
		let $validate-etag := r:validate-incoming-etag ($incoming-etag, $record-etag)
		let $record-exists := r:record-exists ($incoming-uri)
		let $etag-conflict := r:etag-conflict ($incoming-uri, $incoming-etag, $record-etag, $validate-etag, $record-exists)
		return 
			if (fn:empty ($etag-conflict))
			then 
				if ($validate-flag = 'true')
				then
					let $record-rdf-type := $incoming-doc/@typeof
					let $extracted-triples := r:extract-triples ($incoming-doc)
					let $validate-record := r:validate-record ($incoming-doc, $extracted-triples, tokenize($record-rdf-type, ' '))
					return 
						if (fn:empty($validate-record))
						then 
							let $predefined-types := r:extract-predefined-rdf-types ($incoming-doc, $record-rdf-type)
							let $predefined-properties := r:extract-predefined-properties ($incoming-doc, $record-rdf-type)
							let $incoming-doc as node() := if (fn:empty ($predefined-types)) then $incoming-doc else (r:inject-predefined-rdf-types ($incoming-doc, $predefined-types))
							let $incoming-doc as node() := if ($predefined-properties/*) then r:inject-predefined-properties ($incoming-doc, $predefined-properties) else $incoming-doc
							let $created-date as xs:dateTime? := r:get-created-date-for-record ($incoming-uri)
							let $extracted-triples := r:extract-triples ($incoming-doc)
					        let $build-doc as node() := r:build-document ($incoming-doc, $extracted-triples, $created-date)
					        let $collections as xs:string* := r:collections-for-record ($incoming-doc, $extracted-triples, $incoming-uri)
					        return 
								let $_ := xdmp:set-response-code (201, "Created")
								return r:load-record ($build-doc, $incoming-uri, $collections)
						else (
							$validate-record,
							xdmp:set-response-content-type ($const:CT-ERROR-XML),
							xdmp:set-response-code (400, "Bad Request")
							)
				else 
					let $extracted-triples := r:extract-triples ($incoming-doc)
					let $created-date as xs:dateTime? := r:get-created-date-for-record ($incoming-uri)
					let $collections as xs:string* := r:collections-for-record ($incoming-doc, $extracted-triples, $incoming-uri)
					let $build-doc as node() := r:build-document ($incoming-doc, $extracted-triples, $created-date)
					return 
						let $_ := xdmp:set-response-code (201, "Created")
						return r:load-record ($build-doc, $incoming-uri, $collections)
		    else (
				$etag-conflict,
				xdmp:set-response-content-type ($const:CT-ERROR-XML), 
		        xdmp:set-response-code (409, "Conflict")
	        )