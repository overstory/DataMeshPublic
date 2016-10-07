xquery version "1.0-ml";

(:
	Todo: Change this to invoke the MarkLogic endpoint, catch exceptions and map then to our error format.
:)

(: Copyright 2011-2014 MarkLogic Corporation.  All Rights Reserved. :)

import module namespace semmod = "http://marklogic.com/rest-api/models/semantics"
    at "/MarkLogic/rest-api/models/semantics-model.xqy";

import module namespace rest = "http://marklogic.com/appservices/rest"
  at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace conf = "http://marklogic.com/rest-api/endpoints/config"
    at "/MarkLogic/rest-api/endpoints/config.xqy";

import module namespace eput = "http://marklogic.com/rest-api/lib/endpoint-util"
    at "/MarkLogic/rest-api/lib/endpoint-util.xqy";

import module namespace logger = "http://marklogic.com/rest-api/logger"
    at "/MarkLogic/rest-api/lib/logger.xqy";

import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";
import module namespace semi= "http://marklogic.com/semantics/impl" at "/MarkLogic/semantics/sem-impl.xqy";

declare namespace sr = "http://www.w3.org/2005/sparql-results#";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

declare default function namespace "http://www.w3.org/2005/xpath-functions";
declare option xdmp:mapping "false";

declare option xdmp:transaction-mode "auto";

let $params     := rest:process-request(conf:get-sparql-protocol-rule())
let $headers    := eput:get-request-headers()
let $inbound-content-type := eput:get-inbound-content-type($params,$headers)
let $method     := eput:get-request-method($headers)
let $input-type :=
    if ($method eq "GET")
    then "param"
    else if ($method ne "POST")
    then error((), "REST-UNSUPPORTEDMETHOD",$method)
    else if (map:contains($params,"query"))
    then error((),"RESTAPI-INVALIDREQ",
        "query parameter not allowed with POST of SPARQL as request body"
        )
    else "body"
return
    switch ($input-type)
    case "param" return
        let $result := semmod:sparql-query($headers,$params,())
        let $response := semmod:results-payload($headers,$params,$result)
        return
            if (empty($response[2]))
            then xdmp:set-response-code(404,"Not Found")
            else (xdmp:set-response-content-type($response[1]),$response[2])
    case "body" return
        let $body := xdmp:get-request-body(eput:get-content-format($headers,$params))/node()
        let $result := semmod:sparql-query($headers,$params,$body)
        let $response := semmod:results-payload($headers,$params,$result)
        return
            if ($response[2] instance of node() and ($response[2])/self::semmod:malformed-query)
            then (xdmp:set-response-code(400, "Malformed Query"), $response)
            else if (empty($response[2]))
            then xdmp:set-response-code(404,"Not Found")
            (: FixMe: Need to rewrite the <a href="" value to point to DataMesh endpoint :)
            else (xdmp:set-response-content-type($response[1]), if ($response[1] = "text/html") then $response[2]//xhtml:table else $response[2])
    default return
        error((),"RESTAPI-INTERNALERROR",
            concat("unknown input-type ",$input-type)
            )
