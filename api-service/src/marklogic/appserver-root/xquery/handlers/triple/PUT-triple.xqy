xquery version '1.0-ml';

import module namespace const="urn:overstory:modules:data-mesh:handlers:lib:constants" at "../lib/constants.xqy";
import module namespace r="urn:overstory:modules:data-mesh:handlers:lib:records" at "../lib/lib-records.xqy";

declare namespace osc = "http://ns.overstory.co.uk/namespaces/datamesh/content";
declare namespace e = "http://ns.overstory.co.uk/namespaces/error";

declare option xdmp:output "indent=yes";

declare variable $subject as xs:string? := xdmp:get-request-field ("subject", ());
declare variable $predicate as xs:string? := xdmp:get-request-field ("predicate", ());
declare variable $object as xs:string? := xdmp:get-request-field ("object", ());
declare variable $description as xs:string? := xdmp:get-request-field ("description", '');

let $validate-incoming-params := r:validate-triple-params ($subject, $predicate, $object)
return
	if (fn:empty($validate-incoming-params))
	then 
		let $validate-subject := r:check-resource ($subject)
		let $validate-predicate := r:check-curie ($predicate)
		let $validate-object := r:check-curie ($object)
		return
			if ($validate-subject and $validate-predicate and $validate-object)
			then (
			    let $rdfa-triple := r:build-rdfa-triple ($predicate, $object, $description)
			    return 
			        if ( r:triple-exists ($subject, $predicate, $object) )
			        then (
				        xdmp:set-response-code (409, "Conflict"),
				        xdmp:set-response-content-type ($const:CT-ERROR-XML),
				        <e:errors>
				            <e:triple-exists>
				                <e:message>Provided triple already exists</e:message>
				                <e:subject>{$subject}</e:subject>
				                <e:predicate>{$predicate}</e:predicate>
				                <e:object>{$object}</e:object>
				            </e:triple-exists>
				        </e:errors>
			        )
			        else (
			        	r:put-rdfa-triple ($subject, $rdfa-triple), 
				        xdmp:set-response-code (201, "Created")
			        )
			)
			else(
			)
	else (
		$validate-incoming-params,
		xdmp:set-response-code (400, "Bad Request"),
		xdmp:set-response-content-type ($const:CT-ERROR-XML)
	)