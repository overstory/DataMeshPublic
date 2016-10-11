xquery version "1.0-ml";

module namespace endpoints="urn:overstory:rest:modules:endpoints";

import module namespace rce="urn:overstory:rest:modules:common:endpoints" at "lib-rest/common-endpoints.xqy";

declare namespace rest="http://marklogic.com/appservices/rest";

(: ---------------------------------------------------------------------- :)

declare private variable $endpoints as element(rest:options) := <options xmlns="http://marklogic.com/appservices/rest">
	<!-- root -->
	<request uri="^(/?)$" endpoint="/xquery/default.xqy" />

	<!-- Health Check -->
	<request uri="^/health$" endpoint="/xquery/handlers/health/ping.xqy" user-params="allow">
		<http method="GET"/>
	</request>


	<!-- |||||||| -->
	<!--    API   -->
	<!-- |||||||| -->

	<request uri="^/api(/)?$" endpoint="/xquery/handlers/api/GET-api.xqy" user-params="forbid">
		<http method="GET"/>
	</request>

	<!-- |||||||| -->
	<!-- SEARCHES -->
	<!-- |||||||| -->

	<request uri="^/record/type/(.+)$" endpoint="/xquery/handlers/search/GET-record-search.xqy" user-params="allow">
	     <uri-param name="type">$1</uri-param>
		 <http method="GET"/>
	</request>

	<request uri="^/record(/)?$" endpoint="/xquery/handlers/search/GET-record-search.xqy" user-params="allow">
		<http method="GET"/>
	</request>

	<!-- |||||| -->
	<!-- SPARQL -->
	<!-- |||||| -->

	<request uri="^/sparql/(.+)$" endpoint="/xquery/handlers/search/GET-sparql-search.xqy" user-params="allow">
		<uri-param name="sparql">$1</uri-param>
		<http method="GET"/>
	</request>

	<request uri="^/sparql$" endpoint="/xquery/handlers/search/POST-sparql-query.xqy" user-params="allow">
		<http method="POST"/>
	</request>

	<!-- ||||| -->
	<!-- TYPES -->
	<!-- ||||| -->

        <request uri="^/rdf/record/type$" endpoint="/xquery/handlers/type/GET-type.xqy" user-params="allow">
		<http method="GET"/>
	</request>

	<!-- |||||||| -->
	<!-- PREFIXES -->
	<!-- |||||||| -->

	<request uri="^/rdf/prefix/(.+)$" endpoint="/xquery/handlers/prefix/GET-prefix.xqy" user-params="forbid">
		<uri-param name="prefix">$1</uri-param>
		<http method="GET"/>
		<http method="HEAD"/>
	</request>

	<request uri="^/rdf/prefix/(.+)$" endpoint="/xquery/handlers/prefix/PUT-prefix.xqy" user-params="forbid">
	<uri-param name="prefix">$1</uri-param>
		<http method="PUT"/>
	</request>

	<request uri="^/rdf/prefix/(.+)$" endpoint="/xquery/handlers/prefix/DELETE-prefix.xqy" user-params="forbid">
	<uri-param name="prefix">$1</uri-param>
		<http method="DELETE"/>
	</request>

	<request uri="^/rdf/prefix$" endpoint="/xquery/handlers/prefix/GET-prefix-list.xqy" user-params="allow">
		<http method="GET"/>
	</request>

	<!-- ||||||| -->
	<!-- RECORDS -->
	<!-- ||||||| -->

	<request uri="^/record(/)?$" endpoint="/xquery/handlers/record/POST-record.xqy" user-params="forbid">
		<uri-param name="uri">$1</uri-param>
		<http method="POST"/>
	</request>

	<request uri="^/record/id/(.+)$" endpoint="/xquery/handlers/record/GET-record.xqy" user-params="forbid">
		<uri-param name="uri">$1</uri-param>
		<http method="GET"/>
	</request>

	<request uri="^/record/id/(.+)$" endpoint="/xquery/handlers/record/PUT-record.xqy" user-params="allow">
		<uri-param name="uri">$1</uri-param>
		<http method="PUT"/>
	</request>

	<request uri="^/record/id/(.+)$" endpoint="/xquery/handlers/record/DELETE-record.xqy" user-params="forbid">
		<uri-param name="uri">$1</uri-param>
		<http method="DELETE"/>
	</request>

	<!-- ||||||| -->
	<!-- TRIPLES -->
	<!-- ||||||| -->

	<request uri="^/rdf/triple$" endpoint="/xquery/handlers/triple/PUT-triple.xqy" user-params="allow">
		<http method="PUT"/>
	</request>

	<request uri="^/rdf/triple$" endpoint="/xquery/handlers/triple/DELETE-triple.xqy" user-params="allow">
		<http method="DELETE"/>
	</request>


	<!-- ================================================================= -->

	{ $rce:DEFAULT-ENDPOINTS }
</options>;

(: ---------------------------------------------------------------------- :)

declare function endpoints:options (
) as element(rest:options)
{
	$endpoints
};
