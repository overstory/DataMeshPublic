xquery version "1.0-ml";

module namespace rdfa-ttl = "urn:overstory:rdf:rdf-ttl";

declare namespace xsi="http://www.w3.org/2001/XMLSchema-instance";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare variable $dfvocab := "http://www.w3.org/1999/xhtml/vocab#";
declare variable $rdf-XMLLiteral := "http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral";
declare variable $default-base-uri := $dfvocab;

declare variable $htmlrels :=
	( "alternate", "appendix", "bookmark", "cite", "chapter", "contents",
	"copyright", "glossary", "help", "icon", "index", "last", "license",
	"meta", "next", "p3pv1", "prev", "role", "section", "start",
	"stylesheet", "subsection", "up" );

declare variable $vocabulary-terms := ( "describedby", "license", "role" );

(: Preloaded with default vocabulary prefixes.  See: http://www.w3.org/2011/rdfa-context/rdfa-1.1 :)
declare variable $default-prefixes-map := map:map (
	<map:map xmlns:map="http://marklogic.com/xdmp/map" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
		<map:entry key="grddl"><map:value xsi:type="xs:string">http://www.w3.org/2003/g/data-view#</map:value></map:entry>
		<map:entry key="ma"><map:value xsi:type="xs:string">http://www.w3.org/ns/ma-ont#</map:value></map:entry>
		<map:entry key="owl"><map:value xsi:type="xs:string">http://www.w3.org/2002/07/owl#</map:value></map:entry>
		<map:entry key="prov"><map:value xsi:type="xs:string">http://www.w3.org/ns/prov#</map:value></map:entry>
		<map:entry key="rdf"><map:value xsi:type="xs:string">http://www.w3.org/1999/02/22-rdf-syntax-ns#</map:value></map:entry>
		<map:entry key="rdfa"><map:value xsi:type="xs:string">http://www.w3.org/ns/rdfa#</map:value></map:entry>
		<map:entry key="rdfs"><map:value xsi:type="xs:string">http://www.w3.org/2000/01/rdf-schema#</map:value></map:entry>
		<map:entry key="rif"><map:value xsi:type="xs:string">http://www.w3.org/2007/rif#</map:value></map:entry>
		<map:entry key="rr"><map:value xsi:type="xs:string">http://www.w3.org/ns/r2rml#</map:value></map:entry>
		<map:entry key="sd"><map:value xsi:type="xs:string">http://www.w3.org/ns/sparql-service-description#</map:value></map:entry>
		<map:entry key="skos"><map:value xsi:type="xs:string">http://www.w3.org/2004/02/skos/core#</map:value></map:entry>
		<map:entry key="skosxl"><map:value xsi:type="xs:string">http://www.w3.org/2008/05/skos-xl#</map:value></map:entry>
		<map:entry key="wdr"><map:value xsi:type="xs:string">http://www.w3.org/2007/05/powder#</map:value></map:entry>
		<map:entry key="void"><map:value xsi:type="xs:string">http://rdfs.org/ns/void#</map:value></map:entry>
		<map:entry key="wdrs"><map:value xsi:type="xs:string">http://www.w3.org/2007/05/powder-s#</map:value></map:entry>
		<map:entry key="xhv"><map:value xsi:type="xs:string">http://www.w3.org/1999/xhtml/vocab#</map:value></map:entry>
		<map:entry key="xml"><map:value xsi:type="xs:string">http://www.w3.org/XML/1998/namespace</map:value></map:entry>
		<map:entry key="xsd"><map:value xsi:type="xs:string">http://www.w3.org/2001/XMLSchema#</map:value></map:entry>

		<map:entry key="cc"><map:value xsi:type="xs:string">http://creativecommons.org/ns#</map:value></map:entry>
		<map:entry key="ctag"><map:value xsi:type="xs:string">http://commontag.org/ns#</map:value></map:entry>
		<map:entry key="dc"><map:value xsi:type="xs:string">http://purl.org/dc/terms/</map:value></map:entry>
		<map:entry key="dcterms"><map:value xsi:type="xs:string">http://purl.org/dc/terms/</map:value></map:entry>
		<map:entry key="dc11"><map:value xsi:type="xs:string">http://purl.org/dc/elements/1.1/</map:value></map:entry>
		<map:entry key="foaf"><map:value xsi:type="xs:string">http://xmlns.com/foaf/0.1/</map:value></map:entry>
		<map:entry key="gr"><map:value xsi:type="xs:string">http://purl.org/goodrelations/v1#</map:value></map:entry>
		<map:entry key="ical"><map:value xsi:type="xs:string">http://www.w3.org/2002/12/cal/icaltzd#</map:value></map:entry>
		<map:entry key="og"><map:value xsi:type="xs:string">http://ogp.me/ns#</map:value></map:entry>
		<map:entry key="rev"><map:value xsi:type="xs:string">http://purl.org/stuff/rev#</map:value></map:entry>
		<map:entry key="sioc"><map:value xsi:type="xs:string">http://rdfs.org/sioc/ns#</map:value></map:entry>
		<map:entry key="v"><map:value xsi:type="xs:string">http://rdf.data-vocabulary.org/#</map:value></map:entry>
		<map:entry key="vcard"><map:value xsi:type="xs:string">http://www.w3.org/2006/vcard/ns#</map:value></map:entry>
		<map:entry key="schema"><map:value xsi:type="xs:string">http://schema.org/</map:value></map:entry>

		<map:entry key="describedby"><map:value xsi:type="xs:string">http://www.w3.org/2007/05/powder-s#describedby</map:value></map:entry>
		<map:entry key="license"><map:value xsi:type="xs:string">http://www.w3.org/1999/xhtml/vocab#license</map:value></map:entry>
		<map:entry key="role"><map:value xsi:type="xs:string">http://www.w3.org/1999/xhtml/vocab#role</map:value></map:entry>
	</map:map>
);

declare private variable $minimal-prefixes := map:map(
	<map:map xmlns:map="http://marklogic.com/xdmp/map" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
		<map:entry key="owl"><map:value xsi:type="xs:string">http://www.w3.org/2002/07/owl#</map:value></map:entry>
		<map:entry key="rdf"><map:value xsi:type="xs:string">http://www.w3.org/1999/02/22-rdf-syntax-ns#</map:value></map:entry>
		<map:entry key="rdfa"><map:value xsi:type="xs:string">http://www.w3.org/ns/rdfa#</map:value></map:entry>
		<map:entry key="rdfs"><map:value xsi:type="xs:string">http://www.w3.org/2000/01/rdf-schema#</map:value></map:entry>
		<map:entry key="dc"><map:value xsi:type="xs:string">http://purl.org/dc/terms/</map:value></map:entry>
		<map:entry key="dcterms"><map:value xsi:type="xs:string">http://purl.org/dc/terms/</map:value></map:entry>
		<map:entry key="dc11"><map:value xsi:type="xs:string">http://purl.org/dc/elements/1.1/</map:value></map:entry>
		<map:entry key="foaf"><map:value xsi:type="xs:string">http://xmlns.com/foaf/0.1/</map:value></map:entry>
	</map:map>
);

declare private variable $referenced-prefixes := map:map();

declare private variable $default-bnode-ref := "_:";
declare private variable $bnode-map := map:map();

(: ---------------------------------------------------------------------- :)

(:
   FixMe: Need to revisit the logic of this code, see http://www.w3.org/TR/rdfa-syntax/#s_sequence
   Need to pass around a richer set of context, including a stack of incomplete triples and in-scope prefixes.
:)

(: The public entry point to the module :)

declare function rdfa-to-ttl (
        $doc as node()
) as xs:string?
{
	rdfa-to-ttl ($doc, ())
};

declare function rdfa-to-ttl (
        $doc-node as node(),
        $uri as xs:string?
) as xs:string?
{
	let $root := if ($doc-node instance of document-node()) then $doc-node/* else $doc-node
	let $origin-uri := $uri
	let $base-uri := ($root/xhtml:head/xhtml:base/@href, $root/head/base/@href, $root/@xml:base, $uri, $default-base-uri)[1]
	let $_ := map:clear ($referenced-prefixes)
	let $_ := map:clear ($bnode-map)
	let $prefix-map := context-prefix-map ($default-prefixes-map, $root/@prefix/fn:string())

	return render-ttl ( parse-rdfa ($root, (), $base-uri, $prefix-map), $origin-uri, $prefix-map )
};

(: ----------------------------------------------------------------- :)

declare private function render-ttl (
	$triples as element(triple)*,
	$origin-uri as xs:string?,
	$prefix-map as map:map
) as xs:string?
{
	(:
	 emit prefixes
	 for distinct subjects
	 	output prefixed subject
	 		output predicate and object
	 :)

	fn:string-join (
		(
			emit-prefixes ($origin-uri, $referenced-prefixes), "",

			for $triple in $triples
			return emit-triple ($triple)
		), "&#x0a;"
	)
};

declare private function parse-rdfa (
	$node as item(),
	$parent-node as element()?,
	$base-uri as xs:string,
	$prefix-map as map:map
) as element(triple)*
{
	typeswitch ($node)
	case element() return
		let $my-prefixes-map := context-prefix-map ($prefix-map, $node/@prefix/fn:string())

		return (
			triples-for-node ($node, $parent-node, $base-uri, $my-prefixes-map)
			,
			parse-rdfa ($node/*, $node, $base-uri, $my-prefixes-map)
		)
	default return gen-error-triple (wrap-uri ($base-uri), "rdfa:Error")
};

declare private function gen-error-triple (
	$subject as xs:string,
	$object as xs:string
) as element(triple)
{

	<triple>
		<subject>{ $subject }</subject>
		<predicate>{ "rdf:type" }</predicate>
		<object>{ $object }</object>
	</triple>
};

(: ----------------------------------------------------------------- :)

declare private function emit-prefixes (
    $origin-uri as xs:string?,
	$prefix-map as map:map
) as xs:string*
{
	(
		let $_ :=
			for $key in map:keys ($minimal-prefixes)
			return if (map:get ($prefix-map, $key)) then () else map:put ($prefix-map, $key, map:get ($minimal-prefixes, $key))
		for $prefix in map:keys ($prefix-map)
		let $ns-uri-from-map := map:get ($prefix-map, $prefix)
		let $ns-uri :=
		      if (fn:not(fn:starts-with($ns-uri-from-map,'http:') or fn:starts-with($ns-uri-from-map, 'uri')))
		      then
		          (:
		          # Checks to see that prefixes with relative IRIs are not resolved to the document base
                  # It is resolved against the document origin, though, when the result is parsed
                  :)
		          (
		          if ( fn:not ( fn:ends-with($origin-uri, '/') ) )
		          then ( fn:concat($origin-uri, '/', $ns-uri-from-map) )
		          else ( fn:concat($origin-uri, $ns-uri-from-map) )
		          )
		      else $ns-uri-from-map

		order by $prefix
		return fn:concat ("@prefix ", $prefix, ": ", wrap-uri ($ns-uri), " .")
	)

};

declare private function emit-triple (
	$triple as element(triple)
) as xs:string
{
	fn:concat (
		emit-tuple ($triple/subject),
		"&#x0a;	", emit-tuple ($triple/predicate), " ",
		emit-tuple ($triple/object), " ."
	)
};

declare private function emit-tuple (
	$object as element()
) as xs:string
{
	fn:concat (
		if ($object/@rdf:parseType = 'Literal')
		then quote-xml ($object)
		else compact-uri ($object),

		if ($object/(@datatype|@rdf:datatype))
		then fn:concat ("^^", ($object/@datatype, $object/@rdf:datatype)[1])
		else
			if ($object/@xml:lang)
			then fn:concat ("@", $object/@xml:lang/fn:string())
			else ()

	)
};

declare private function quote-xml (
	$node as element()
) as xs:string
{
	fn:concat ('"""', xdmp:quote ($node/node()), '"""^^rdf:XMLLiteral')
};

declare private function compact-uri (
	$uri as xs:string
) as xs:string
{
	if (fn:not (fn:starts-with ($uri, "<") and fn:ends-with ($uri, ">")))
	then $uri
	else
		let $bare-uri := fn:substring-after (fn:substring-before ($uri, ">"), "<")
		let $prefix := find-prefix-for ($bare-uri)
		let $ns-uri := map:get ($referenced-prefixes, $prefix)
		let $local-part := fn:substring-after ($bare-uri, $ns-uri)

		return
		if ($prefix and $local-part and fn:not (fn:matches ($local-part, "[^\w\d\-_.]")))
		then fn:concat ($prefix, ":", $local-part)
		else $uri
};

declare private function find-prefix-for (
	$uri as xs:string
) as xs:string?
{
	(
		for $prefix in map:keys ($referenced-prefixes)
		let $ns-uri := (map:get ($referenced-prefixes, $prefix)	)[1]
		return
		if (fn:starts-with ($uri, $ns-uri))
		then $prefix
		else ()
	)[1]
};

(: ----------------------------------------------------------------- :)

declare private function triples-for-node (
	$node as element(),
	$parent-node as element()?,
	$root-base-uri as xs:string,
	$prefix-map as map:map
) as element(triple)*
{
	(:
	CheckMe: Is this correct for recursive calls?  Is $root-base-uri the closest in-scope, or the doc root setting?
		xml:base rules:
		1. If node has an ancestor-or-self that have a @xml:base set to blank then the base-uri is restarted to the root-base-uri (either default or specified by the user)
		2. If node has an ancestor-or-self that have a @xml:base set then that base-uri is used
		3. Otherwise if 1 and 2 is false then root-baseuri is used as base-uri
	:)
	let $base-uri :=
		if ($node/ancestor::*[@xml:base = ''])
		then ($root-base-uri)
		else if ($node/self::*[@xml:base]/string(@xml:base) or $node/ancestor::*[@xml:base]/string(@xml:base))
		then ($node/self::*[@xml:base]/string(@xml:base), $node/ancestor::*[@xml:base]/string(@xml:base))[1]
		else ($root-base-uri)
	return (
		(: Function mapping is in play here, it prevents functions being called when the attribute is not present :)
		gen-vocab ($node/@vocab/fn:normalize-space(.), $node, $base-uri, $prefix-map),
		gen-property ($node/@property/fn:normalize-space(.), $node, $parent-node, $base-uri, $prefix-map),
		gen-rel ($node/@rel/fn:normalize-space(.), $node, $parent-node, $base-uri, $prefix-map),
		gen-rev ($node/@rev/fn:normalize-space(.), $node, $parent-node, $base-uri, $prefix-map),
		gen-typeof ($node/@typeof/fn:normalize-space(.), $node, $parent-node, $base-uri, $prefix-map)
	)
};

declare private function subject (
	$node as element(),
	$parent-node as element()?,
	$base-uri as xs:string,
	$prefix-map as map:map
) as xs:string?
{
	if (has-about ($node/@about))
	then resolve-uri-or-curie ($node/@about, $node, $base-uri, $prefix-map)
	else
		if ($node/@href and ($node/@property) and (($node/@content or $node/@datatype)))
		then resolve-uri-or-curie ($node/@href, $node, $base-uri, $prefix-map)
		else
			if ($node/@src and ($node/@property) and (($node/@content or $node/@datatype)))
			then resolve-uri-or-curie ($node/@src, $node, $base-uri, $prefix-map)
			else
			    if ( $node/@typeof and not($node/parent::*) and not(has-about($node/@about)) )
			    then wrap-uri ($base-uri)
				else if ($node/@typeof and not(has-about($node/ancestor::*)))
				then gen-blank-node-uri($node)
				else
					if (fn:exists ($parent-node))
					then subject-parent ($parent-node, $base-uri, $prefix-map)
					else wrap-uri ($base-uri)
};

declare private function subject-parent (
    $node as element(),
	$base-uri as xs:string,
	$prefix-map as map:map
) as xs:string?
{
    if (has-resource ($node/@resource))
    then resolve-uri-or-curie ($node/@resource, $node, $base-uri, $prefix-map)
        else if ( $node/@rev or $node/@rel)
        then gen-blank-node-uri ($node)
            else if (has-about ($node/@about))
            then resolve-uri-or-curie ($node/@about, $node, $base-uri, $prefix-map)
                else if ( $node/@typeof and not($node/parent::*) and not(has-about($node/@about)) )
			    then wrap-uri ($base-uri)
                    else if ($node/@typeof)
                    then gen-blank-node-uri ($node)
                        else if ($node/parent::*)
                        then subject-parent($node/parent::*, $base-uri, $prefix-map)
                             else wrap-uri ($base-uri)

};

declare private function object (
	$node as element(),
	$is-xml as xs:boolean,
	$base-uri as xs:string,
	$prefix-map as map:map
) as item()*
{
	if ($is-xml)
	then ( $node/node() )
	else if (has-resource ($node/@resource) and fn:not ($node/@rel) and fn:not ($node/@rev))
	then resolve-uri-or-curie ($node/@resource, $node, $base-uri, $prefix-map)
	else if (has-href ($node/@href) and fn:not ($node/@content) and fn:not ($node/@datatype))
	then resolve-uri-or-curie ($node/@href, $node, $base-uri, $prefix-map)
	else if (has-src ($node/@src) and fn:not ($node/@content) and fn:not ($node/@datatype))
	then resolve-uri-or-curie ($node/@src, $node, $base-uri, $prefix-map)
	(: unless @about is '[]' the new object is set if @typeof is present :)
	else if ($node/@typeof and fn:not (has-about ($node/@about)) and fn:not ($node/@about='[]') and fn:not($node/@about=''))
	then gen-blank-node-uri ($node)

	else quoted-string (($node/@content, fn:string ($node), "")[1])
};

declare private function quoted-string (
	$s as xs:string
) as xs:string
{
	let $s := fn:replace ($s, '"', '\\"')
	return
	if (fn:matches ($s, "[^ -~'""]"))
	then fn:concat ('"""', $s, '"""')
	else fn:concat ('"', $s, '"')
};

(: ----------------------------------------------------------------- :)

declare private function gen-property (
	$props as xs:string,
	$node as element(),
	$parent-node as element()?,
	$base-uri as xs:string,
	$prefix-map as map:map
) as element(triple)*
{
	for $prop in tokenize ($props, "\s+")
	let $vocab := ancestor-vocab ($node)
	let $predicate :=
	   if ( fn:not ( fn:contains($prop, ':') ) and ( $vocab != '' ) )
	   then ( wrap-uri ( fn:concat ($vocab, $prop) ) )
	   else ( resolve-uri-or-curie ($prop, $node, $base-uri, $prefix-map) )
	let $is-xml as xs:boolean := is-xml ($node, $base-uri, $prefix-map)
	let $datatype := if ($is-xml) then () else effective-datatype ($node, $prefix-map)
	let $lang := effective-lang ($node, $parent-node)	(: ToDo: use ancestor-or-self:: instead? :)
	let $parse-type := if ($is-xml) then "Literal" else ()
	let $subject := subject ($node, $parent-node, $base-uri, $prefix-map)
	let $object := object ($node, $is-xml, $base-uri, $prefix-map)
	return
	if (fn:starts-with ($predicate, "_:"))
	then ()
	(: subjects without curies should not be processed if @vocab=''
       <root>
        <head>
          <title>Test 0318</title>
        </head>
        <body>
          <div vocab="http://xmlns.com/foaf/0.1/">
            <div about="#me">
              <p property="name">Ivan Herman</p>
              <meta vocab="" property="foaf:prop" content="value"/>
            </div>
          </div>
        </body>
      </root>

      foaf:prop should display

      <root>
        <head>
          <title>Test 0318</title>
        </head>
        <body>
          <div vocab="http://xmlns.com/foaf/0.1/">
            <div about="#me">
              <p property="name">Ivan Herman</p>
              <meta vocab="" property="prop" content="value"/>
            </div>
          </div>
        </body>
      </root>

      prop should be ignored
    :)
	else if ( $vocab = '' and not(contains($prop, ':')) )
	then ()
	else
	if ($predicate)
	then
		<triple>
			<subject>{ $subject }</subject>
			<predicate>{ $predicate }</predicate>
			<object>{
				$lang,
				if ($datatype) then attribute rdf:datatype { $datatype } else (),
				if ($parse-type) then attribute rdf:parseType { $parse-type } else (),
				$object
			}</object>
		</triple>
	else gen-error-triple (wrap-uri ($base-uri), "rdfa:UnresolvedTerm")
};

declare private function gen-rel (
	$val as xs:string,
	$node as element(),
	$parent-node as element()?,
	$base-uri as xs:string,
	$prefix-map as map:map
) as element(triple)*
{
	if (has-resource ($node/@resource) or has-href ($node/@href) or has-src ($node/@src) )
	then gen-relrev-immediate ($node, $parent-node, $val, "rel", $base-uri, $prefix-map)
	else (
		relrev-hanging ($node, $parent-node, $val, 'rel', $base-uri, $prefix-map),
		relrev-hanging-bnode ($node, $val, 'rel', $base-uri, $prefix-map)
	)
};

declare private function gen-rev (
	$val as xs:string,
	$node as element(),
	$parent-node as element()?,
	$base-uri as xs:string,
	$prefix-map as map:map
) as element(triple)*
{
	if (has-resource ($node/@resource) or has-href ($node/@href) or has-src ($node/@src) )
	then gen-relrev-immediate ($node, $parent-node, $val, "rev", $base-uri, $prefix-map)
	else
	(
	   relrev-hanging ($node, $parent-node, $val, 'rev', $base-uri, $prefix-map),
	   relrev-hanging-bnode ($node, $val, 'rev', $base-uri, $prefix-map)
	)
};

declare private function gen-vocab (
    $vocab as xs:string,
    $node as element(),
    $base-uri as xs:string,
    $prefix-map as map:map
) as element(triple)*
{
   if ( fn:not($vocab eq '') )
   then
        <triple>
            <subject>{ wrap-uri ( $base-uri ) }</subject>
            <predicate>{string('rdfa:usesVocabulary')}</predicate>
            <object>{ wrap-uri ( $vocab ) }</object>
        </triple>
   else ()
};

declare function gen-relrev-immediate (
	$node as node(),
	$parent-node as element()?,
	$val as xs:string,
	$relorrev as xs:string,
	$base-uri as xs:string,
	$prefix-map as map:map
) as element(triple)*
{
	for $relv in tokenize($val, "\s+")
	let $prefix := fn:substring-before ($relv, ":")
	let $locobj :=
		if (has-resource ($node/@resource))
		then resolve-uri-or-curie ($node/@resource, $node, $base-uri, $prefix-map)
		else if (has-resource ($node/@href))
		then resolve-uri-or-curie ($node/@href, $node, $base-uri, $prefix-map)
		else if (has-resource ($node/@src))
		then resolve-uri-or-curie ($node/@src, $node, $base-uri, $prefix-map)
		   else resolve-uri ($node/@href, $base-uri)
	let $locsbj := subject ($node, $parent-node, $base-uri, $prefix-map)
	let $effective-sbj := if ($relorrev eq "rel") then $locsbj else $locobj
	let $effective-obj := if ($relorrev eq "rel") then $locobj else $locsbj

	return
       	<triple>
       		<subject>{ $effective-sbj }</subject>
       		<predicate>{ resolve-uri-or-curie ($relv, $node, $base-uri, $prefix-map) }</predicate>
       		<object>{ $effective-obj }</object>
       	</triple>
};

declare function hanging-descendants (
	$node as node()
) as node()*
{
    (: find all descendant nodes with hanging-triple-completing-via-new-node attributes... :)
    $node//*[@src or has-about (@about) or @typeof or @href or has-resource (@resource)][count(($node//* intersect ./ancestor::*)/(@src | @about | @typeof | @href | @resource)) eq 0]
      (: but exclude stuff we've already seen, and stuff more than one level deep
         (the deeper stuff is "yet to be seen") :)
};

declare function hanging-bnode (
	$node as node()
) as node()*
{
	(: find all descendant nodes with hanging-triple-completing-via-the-same-bnode attributes... :)
	$node//*[@rel or @rev or @property][count(($node//* intersect ./ancestor::*)/(@rel | @rev | @property)) eq 0]
	(: but exclude stuff we've already seen, and stuff more than one level deep
	 (the deeper stuff is "yet to be seen") :)
};

declare function relrev-hanging (
	$node as node(),
	$parent-node as element()?,
	$val as xs:string,
	$relorrev as xs:string,
	$base-uri as xs:string,
	$prefix-map as map:map
) as element()*
{

	for $rel-rev in if (normalize-space($val) eq "") then () else tokenize($val, "\s+")
	let $prefix := substring-before($rel-rev, ":")
	let $local-subject := subject($node, (), $base-uri, $prefix-map)
	for $hang-desc in hanging-descendants($node)
	let $local-object :=
            if ($hang-desc/@about[fn:starts-with(., '[_:')])
            then ()
            else if (has-about ($hang-desc/@about))
            then resolve-uri-or-curie ($hang-desc/@about, $hang-desc, $base-uri, $prefix-map)
            else if ($hang-desc/@src)
            then resolve-uri-or-curie ($hang-desc/@src, $hang-desc, $base-uri, $prefix-map)
            else if ($hang-desc/@typeof)
            then gen-blank-node-uri ($hang-desc)
            else if ($hang-desc/(@rel | @rev))
            then ()
            else if (has-resource ($hang-desc/@resource))
            then resolve-uri-or-curie ($hang-desc/@resource, $hang-desc, $base-uri, $prefix-map)
            else if ($hang-desc/@href)
            then resolve-uri-or-curie ($hang-desc/@href, $hang-desc, $base-uri, $prefix-map)

                else gen-blank-node-uri ($hang-desc)
	let $subject := if ($relorrev eq "rel") then $local-subject else $local-object
	let $object := if ($relorrev eq "rel") then $local-object else $local-subject

	return
	if ($local-subject and $local-object)
	then
		<triple>
			<subject>{ $subject }</subject>
			<predicate>{ resolve-uri-or-curie ($rel-rev, $node, $base-uri, $prefix-map) }</predicate>
			<object>{ $object }</object>
		</triple>
	else ()
};

declare function relrev-hanging-bnode(
	$node as node(),
	$val as xs:string,
	$relorrev as xs:string,
	$base-uri as xs:string,
	$prefix-map as map:map
) as element()*
{
	for $rel-rev in if (normalize-space($val) eq "") then () else tokenize($val, "\s+")
	let $local-subject := subject($node, (), $base-uri, $prefix-map)
	let $local-object := gen-blank-node-uri($node)
	let $subject := if ($relorrev eq "rel") then $local-subject else $local-object
	let $object := if ($relorrev eq "rel") then $local-object else $local-subject

	return
	if (hanging-bnode($node))
	then
		<triple>
			<subject>{ $subject }</subject>
			<predicate>{ resolve-uri-or-curie ($rel-rev, $node, $base-uri, $prefix-map) }</predicate>
			<object>{ $object }</object>
		</triple>
	else ()
};



declare private function gen-typeof (
	$props as xs:string,
	$node as element(),
	$parent-node as element()?,
	$base-uri as xs:string,
	$prefix-map as map:map
) as element(triple)*
{
	for $type in tokenize ($props, "\s+")
	(: todo: make function subject-typeof :)
	let $local-subject :=
	           if (has-about ($node/@about))
                   then resolve-uri-or-curie($node/@about, $node, $base-uri, $prefix-map)
                   else if ($node/@src)
                        then resolve-uri-or-curie($node/@src, $node, $base-uri, $prefix-map)
                        else if (local-name($node) = ("head", "body"))
                             then wrap-uri($base-uri)
                             else if (has-resource ($node/@resource) and not($node/(@rel | @rev)))
                                  then resolve-uri-or-curie($node/@resource, $node, $base-uri, $prefix-map)
                                  else if ($node/@href and not($node/(@rel | @rev)))
                                       then resolve-uri-or-curie($node/@href, $node, $base-uri, $prefix-map)
                                       else if (fn:not ($node/parent::*) and fn:not(has-about($node/@about)))
                                       then wrap-uri($base-uri)
                                           else if ($node/@about = '')
                                           then (wrap-uri ($base-uri))
                                                else gen-blank-node-uri($node)

    let $vocab := ancestor-vocab ($node)
	let $object :=
	   if ( fn:not ( fn:contains($type, ':') ) and ( $vocab != '' ) )
	   then ( wrap-uri ( fn:concat ($vocab, $type) ) )
	   else ( resolve-uri-or-curie ($type, $node, $base-uri, $prefix-map) )

	return
	<triple>
		<subject>{ $local-subject }</subject>
		<predicate>rdf:type</predicate>
		<object>{ $object }</object>
	</triple>
};

(: ----------------------------------------------------------------- :)

declare private function context-prefix-map (
	$current-map as map:map,
	$prefix-def as xs:string?
) as map:map
{
	if (fn:empty ($prefix-def))
	then $current-map
	else (
		let $new-map := $current-map + map:map()
		let $local-prefix-map := map-from-prefixes ($prefix-def)
		let $_ :=
			for $key in map:keys ($local-prefix-map)
			return map:put ($new-map, $key, map:get ($local-prefix-map, $key))
		return $new-map
	)
};

declare function map-from-prefixes (
        $prefixes-str as xs:string
) as map:map
{
        let $tokens := tokenize ($prefixes-str, "\s+")
        let $map := map:map()
        let $_ :=
                for $token at $idx in $tokens
                return
                if ((($idx mod 2) = 1) and ($token ne "_:") and fn:ends-with ($token, ":") and (fn:substring-before ($token, ":") castable as xs:NCName))
                then map:put ($map, fn:substring-before ($token, ":"), $tokens[$idx + 1])
                else ()
        let $_ :=
        	for $key in map:keys ($map)
        	return map:put ($referenced-prefixes, $key, map:get ($map, $key))
        return $map
};


declare private function namespace-uri-for-prefix (
        $prefix as xs:string,
	    $prefix-map as map:map,
        $node as node(),
        $base-uri as xs:string?
) as xs:string?
{
        let $uri as xs:string? := map:get ($prefix-map, $prefix)
        let $uri as xs:string? := if (fn:exists ($uri)) then $uri else map:get ($default-prefixes-map, $prefix)
        let $uri as xs:string? := if (fn:exists ($uri) or ($prefix = "_")) then $uri else fn:namespace-uri-for-prefix ($prefix, $node)
        (:
        needs something like this, however better to add this when prefix map is generated.
        let $test as xs:string? :=
            if (fn:exists ($uri) and not(fn:starts-with($uri, 'http') or fn:starts-with($uri, 'uri')))
            then
            concat($base-uri, $uri)
            else $uri
            :)
	    let $_ := if (fn:exists ($uri)) then map:put ($referenced-prefixes, $prefix, $uri) else ()

        return $uri
};

(: ----------------------------------------------------------------- :)

declare function effective-datatype (
	$node as element(),
	$prefix-map as map:map
) as xs:string?
{
	if ($node/@datatype)
	then ( resolve-curie ($node/@datatype, $node, (), $prefix-map) )
	else if ($node/@rdf:datatype)
	then ( resolve-curie ($node/@rdf:datatype, $node, (), $prefix-map) )
	else ()

};

declare function effective-lang (
	$node as element(),
	$parent-node as element()
) as attribute()?
{
	if ($node/(@xml:lang|@lang))
	then attribute xml:lang { (($node/@xml:lang/fn:string()), $node/@lang/fn:string())[1] }
	else (effective-lang ($parent-node, $node/parent::*))

	(: alternative: :)
	(: ($node/ancestor-or-self::*/@xml:lang)[position() eq last()] :)
};

(: ----------------------------------------------------------------- :)

declare private variable $default-bnode-id := "_:defbnode";

declare private function resolve-curie (
	$val as xs:string,
	$node as element(),
	$base-uri as xs:string?,
	$prefix-map as map:map
) as xs:string?
{
	let $curie :=
		if (fn:starts-with ($val, "[") and fn:ends-with ($val, "]"))
		then fn:substring-after (fn:substring-before ($val, "]"), "[")
		else $val
	let $prefix := if ($curie = $vocabulary-terms) then $curie else fn:substring-before ($curie, ":")
	let $ns-uri :=
		if (fn:not ($prefix) or (fn:starts-with ($curie, ":")))
		then $dfvocab
		else
			if ($curie = $vocabulary-terms)
			then map:get ($default-prefixes-map, $curie)
			else namespace-uri-for-prefix ($prefix, $prefix-map, $node, $base-uri)
	let $suffix := fn:substring-after ($curie, ":")
	let $result :=
		if ($prefix = "_")
		then if ($curie = $default-bnode-ref) then (map:get ($bnode-map, $default-bnode-ref), $default-bnode-id)[1] else $curie
		else if ($prefix = "" and fn:starts-with ($curie, ':'))
		then fn:concat ("<", $dfvocab, $suffix, ">")
		else

		    if ((($ns-uri eq $dfvocab) and ($suffix = $htmlrels)) or ($prefix and $ns-uri))
			then fn:concat ("<", $ns-uri, $suffix, ">")

			else ()

	return $result
};

declare function resolve-uri (
	$val as xs:string,
	$base-uri as xs:string
) as xs:string
{
	let $uri :=
		if (fn:starts-with ($val, ":") or fn:ends-with ($val, ":"))
		then $base-uri
		else
			if (fn:starts-with ($val, "#"))
			then fn:concat ($base-uri, $val)
			else
				if ($val = $vocabulary-terms)
				then map:get ($default-prefixes-map, $val)
				else fn:resolve-uri ($val, $base-uri)
	return wrap-uri ($uri)
};

declare private function resolve-uri-or-curie (
	$val as xs:string,
	$node as element(),
	$base-uri as xs:string,
	$prefix-map as map:map
) as xs:string
{
	(resolve-curie ($val, $node, $base-uri, $prefix-map), resolve-uri ($val, $base-uri))[1]
};

declare function wrap-uri (
	$uri as xs:string
) as xs:string
{
	fn:concat ("<", $uri, ">")
};

declare function unwrap-uri (
	$uri as xs:string
) as xs:string
{
	let $string-length as xs:int := fn:string-length ($uri) - 2

	return fn:substring ($uri, 2, $string-length)
};

(: ----------------------------------------------------------------- :)

declare function gen-blank-node-uri (
	$node as element()
) as xs:string
{
	let $node-id := concat ("_:b", $node/fn:generate-id ($node))
	let $_ := if (map:get ($bnode-map, $default-bnode-ref)) then () else map:put ($bnode-map, $default-bnode-ref, $node-id)
	let $_ := map:put ($bnode-map, $node-id, $node-id)

	return $node-id
};


declare private function is-xml (
	$node as element(),
	$base-uri as xs:string,
	$prefix-map as map:map
) as xs:boolean
{
	$node/@datatype and (unwrap-uri (resolve-curie ($node/@datatype, $node, (), $prefix-map)) = $rdf-XMLLiteral)
};

(: returns first ancestor @vocab :)
declare private function ancestor-vocab (
    $node as element()
) as xs:string*
{
    $node/ancestor-or-self::*[@vocab][1]/@vocab
};

(: function mapping will cause empty sequence result if $about is empty, which evaluates as false :)
declare private function has-about (
	$about as xs:string
) as xs:boolean
{
	$about and fn:not ($about = ("[]"))
};

(: function mapping will cause empty sequence result if $about is empty, which evaluates as false :)
declare private function has-resource (
	$resource as xs:string
) as xs:boolean
{
	$resource and fn:not ($resource = ("[]"))
};

declare private function has-href (
	$href as xs:string
) as xs:boolean
{
	$href and fn:not ($href = ("[]"))
};

declare private function has-src (
	$src as xs:string
) as xs:boolean
{
	$src and fn:not ($src = ("[]"))
};

(: ----------------------------------------------------------------- :)
(: ----------------------------------------------------------------- :)
(: ----------------------------------------------------------------- :)



(:
	let $curie :=
		if (fn:starts-with ($val, "[") and fn:ends-with ($val, "]"))
		then fn:substring-after (fn:substring-before ($val, "]"), "[")
		else $val
	let $p := fn:substring-before ($curie, ":")
	let $n := if ($p) then namespace-uri-for-prefix ($p, $prefix-map, $node) else ()
	let $prefix := if (fn:exists ($n)) then $p else ()
	let $ns-uri :=
		if ($n)
		then $n
		else
			if (fn:starts-with ($curie, ":"))
			then $dfvocab
			else if ($curie castable as xs:NCName) then $base-uri else ()
	let $suffix :=
		if ($prefix and ($ns-uri = $dfvocab))
		then ()
		else
			if ($prefix or starts-with ($curie, ":"))
			then fn:substring-after ($curie, ":")
			else $curie
	let $uri := fn:concat ($ns-uri, $suffix)

	return
	<parsed-curie>
		<curie>{ $curie }</curie>
		<prefix>{ $prefix }</prefix>
		<suffix>{ $suffix }</suffix>
		<ns-uri>{ $ns-uri }</ns-uri>
		<expanded-uri>{ $uri }</expanded-uri>
		<uri>{ if (fn:exists ($prefix)) then $curie else $uri }</uri>
		<ttl>{ if (fn:exists ($prefix)) then $curie else fn:concat ("<", $uri, ">") }</ttl>
	</parsed-curie>
:)

(:
declare private function rdfa-property-value (
	$val as xs:string,
	$node as element(),
	$base-uri as xs:string,
	$prefix-map as map:map
) as element(attr-value)
{
	let $curie :=
		if (fn:starts-with ($val, "[") and fn:ends-with ($val, "]"))
		then fn:substring-after (fn:substring-before ($val, "]"), "[")
		else $val
	let $p := fn:substring-before ($curie, ":")
	let $n := namespace-uri-for-prefix ($p, $prefix-map, $node)
	let $prefix := if (fn:exists ($n)) then $p else ()
	let $ns-uri :=
		if (fn:exists ($n))
		then $n
		else
			if (fn:starts-with ($curie, ":"))  (: CheckMe :)
			then $dfvocab
			else $base-uri
	let $tokens := if (fn:exists ($prefix)) then fn:tokenize ($curie, ":") else ()
	let $local-name := if (fn:count ($tokens) = 0) then $curie else $tokens[fn:last()]
	let $full-value := if (fn:empty ($prefix) and fn:empty ($ns-uri)) then $curie else fn:concat ($ns-uri, $local-name)

	return
	<attr-value>
		<prefix>{ $prefix }</prefix>
		<ns-uri>{ $ns-uri }</ns-uri>
		<local-name>{ $local-name }</local-name>
		<curie>{ $curie }</curie>
		<full-value>{ $full-value }</full-value>
	</attr-value>
};

declare private function expanded-curie (
	$attr-value as element(attr-value),
	$prefix-map as map:map
) as xs:string
{
	if (map:get ($prefix-map, $attr-value/prefix/fn:string()))
	then $attr-value/curie/fn:string()
	else $attr-value/full-value/fn:string()
};

declare private function expanded-curie-attr (
	$attr-value as xs:string,
	$node as element(),
	$base-uri as xs:string,
	$prefix-map as map:map
) as xs:string
{
	expanded-curie (rdfa-property-value ($attr-value, $node, $base-uri, $prefix-map), $prefix-map)
};
:)

(:
declare private function expand-curie (
	$curie as xs:string,
	$node as element(),
	$base-uri as xs:string,
	$prefix-map as map:map
) as xs:string
{
	let $parts := parse-curie ($curie, $node, $base-uri, $prefix-map)
	return
	if ($parts/prefix = "_")
	then $curie
	else $parts/uri/fn:string()
};
:)

(: ----------------------------------------------------------------- :)

