xquery version "1.0-ml";

import module namespace rconst="urn:overstory:rest:modules:constants" at "../../rest/lib-rest/constants.xqy";

try {
	let $doc-count := xdmp:estimate (fn:doc())
	let $message :=
	'{
		"status" : "OK",
		"message" : "Database contains ' || $doc-count || ' documents"
	}'
	let $_ := xdmp:set-response-content-type ($rconst:MEDIA-TYPE-STANDARD-JSON)
	return $message
} catch ($e) {
	let $message :=
	'{
		"status" : "ERROR",
		"message" : "Error detected: ' || $e//error:format-string/fn:string() || '"
	}'
	let $_ := xdmp:set-response-content-type ($rconst:MEDIA-TYPE-STANDARD-JSON)
	let $_ := xdmp:set-response-code ($rconst:HTTP-INTERNAL-SERVER-ERROR, "Server Error")

	return $message
}
