xquery version '1.0-ml';

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "../lib/constants.xqy";
import module namespace r="urn:overstory:modules:data-mesh:handlers:lib:records" at "../lib/lib-records.xqy";

declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";
declare namespace e = "http://ns.overstory.co.uk/namespaces/error";

declare option xdmp:output "indent=yes";

declare variable $prefix-uri as xs:anyURI := xdmp:get-request-body();
declare variable $prefix-name as xs:string := xdmp:get-request-field ("prefix", ());
declare variable $prefix-identifier as xs:string := r:build-prefix-uri($prefix-name);
declare variable $incoming-etag as xs:string? := xdmp:get-request-header ("etag", "");

let $validate-incoming-prefix-uri := r:validate-prefix-uri ($prefix-uri)
return
	if (fn:empty($validate-incoming-prefix-uri))
	then 
		let $record-etag as xs:string? := r:etag-from-record-uri ($prefix-identifier)
		let $validate-etag := r:validate-incoming-etag ($incoming-etag, $record-etag)
		return
			if (fn:not ($validate-etag) and r:record-exists ($prefix-identifier))
			then (
				<e:errors>
		            <e:etag-mismatch>
		                <e:message>Given ETag value does not match current resource ETag</e:message>
		                <e:given-etag>{$incoming-etag}</e:given-etag>
		                <e:current-etag>{$record-etag}</e:current-etag>
		            </e:etag-mismatch>
		        </e:errors>,
		        xdmp:set-response-content-type ($const:CT-ERROR-XML), 
		        xdmp:set-response-code (409, "Conflict")
			)
			else 
				let $prefix-doc as node() := r:build-prefix-document ($prefix-identifier, $prefix-name, $prefix-uri)
				let $extracted-triples := r:extract-triples ($prefix-doc)
				let $collections := r:collections-for-record ($prefix-doc, $extracted-triples, $prefix-identifier)
				let $created-date as xs:dateTime? := r:get-created-date-for-record ($prefix-identifier)
				let $build-doc := r:build-document ($prefix-doc, $extracted-triples, $created-date)
				return (
					r:load-record($build-doc, $prefix-identifier, $collections),
					xdmp:set-response-code (201, "Created")
				)
	else 
	(
		$validate-incoming-prefix-uri,
		xdmp:set-response-code (400, "Bad Request"),
		xdmp:set-response-content-type ($const:CT-ERROR-XML)
	)