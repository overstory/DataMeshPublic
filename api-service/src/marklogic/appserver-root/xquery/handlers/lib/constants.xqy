xquery version '1.0-ml';

module namespace article="urn:overstory:modules:data-mesh:handlers:lib:constants";

declare option xdmp:output "indent=yes";

declare variable $ML-DEFAULT-GRAPH-URI := "http://marklogic.com/semantics#default-graph";

(: todo:remove this:)
declare variable $DATA-MESH-URI-SPACE-ROOT := "http://datamesh.overstory.co.uk/resources/";
declare variable $DATA-MESH-COLLECTION-URI := "urn:overstory.co.uk:collection:data-mesh";
declare variable $DATA-MESH-ELEMENT-NAMESPACE-URI := "http://datamesh.overstory.co.uk";

declare variable $OSC-NAMESPACE := "http://ns.overstory.co.uk/namespaces/datamesh/content";

declare variable $RECORD-COLLECTION := "urn:overstory.co.uk:collection:record";
declare variable $SEARCHABLE-COLLECTION := "http://rdf.overstory.co.uk/rdf/terms/DataRecord";

declare variable $RDF-PREFIX-COLLECTION := "urn:overstory.co.uk:collection:config:rdf:prefixes";
declare variable $RDF-TYPE-COLLECTION := "urn:overstory.co.uk:collection:rdf-types";

declare variable $ADDRESS-COLLECTION := "urn:overstory.co.uk:collection:address";
declare variable $CONTRACT-COLLECTION := "urn:overstory.co.uk:collection:contract";
declare variable $ENGAGEMENT-COLLECTION := "urn:overstory.co.uk:collection:engagement";
declare variable $EVENT-COLLECTION := "urn:overstory.co.uk:collection:event";
declare variable $GROUP-COLLECTION := "urn:overstory.co.uk:collection:group";
declare variable $INVOICE-COLLECTION := "urn:overstory.co.uk:collection:invoice";
declare variable $ORGA-COLLECTION := "urn:overstory.co.uk:collection:organization";
declare variable $PARTICIPATION-COLLECTION := "urn:overstory.co.uk:collection:participation";
declare variable $PERSON-COLLECTION := "urn:overstory.co.uk:collection:person";
declare variable $PROJECT-COLLECTION := "urn:overstory.co.uk:collection:project";
declare variable $TASK-COLLECTION := "urn:overstory.co.uk:collection:task";
declare variable $TIMESHEET-COLLECTION := "urn:overstory.co.uk:collection:timesheet";
declare variable $WORKORDER-COLLECTION := "urn:overstory.co.uk:collection:workorder";

declare variable $RECORD-CONTENT-TYPE := "application/xml";
declare variable $ERROR-CONTENT-TYPE := "application/xml";

declare variable $PREFIX-DOCUMENT-URI := "/config/rdf/prefixes.xml";
declare variable $API-DOCUMENT-URI := "urn:overstory.co.uk:id:api:bootstrap";

declare variable $CT-ATOM-XML := "application/atom+xml";
declare variable $CT-XML := "application/xml";
declare variable $CT-RECORD-XML := "application/vnd.overstory.record+xml";
declare variable $CT-TYPE-XML := "application/vnd.overstory.type+xml";
declare variable $CT-PREFIX-XML := "application/vnd.overstory.prefix+xml";
declare variable $CT-ERROR-XML := "application/vnd.overstory.rest.errors+xml";

declare variable $PREFIX-SPARQL := 'PREFIX ost: <http://rdf.overstory.co.uk/rdf/terms/> SELECT ?search WHERE { ?search a ost:Prefix }';
declare variable $PREFIX-CURIE := 'ost:Prefix';
declare variable $PREFIX-FULL-URI := 'http://rdf.overstory.co.uk/rdf/terms/Prefix';

declare variable $ELEMENT-MAPPING-SPARQL-TEMPLATE := "SELECT ?elementName ?elementNs WHERE { ?s a ost:RdfElementMap . ?s ost:rdfType 'predicate-name' . ?s ost:elementQName ?elementName . OPTIONAL { ?s ost:elementNs ?elementNs } }";

declare variable $NS-FROM-PREFIX-SPARQL-TEMPLATE := "SELECT ?prefixUri WHERE { ?s a ost:Prefix . ?s ost:prefixName 'prefix-name' . ?s ost:prefixUri ?prefixUri }";

declare variable $REQUIRED-PROPERTIES-FROM-RDF-TYPE-SPARQL-TEMPLATE :=
"SELECT ?minOccurs ?maxOccurs ?propName ?propType WHERE
{
	?s a ost:RecordDefinition . ?s ost:rdfType 'incoming-rdf-type' .
	?s ost:recordProperty ?ostProperties .
	OPTIONAL { ?ostProperties ost:minOccurs ?minOccurs  . ?ostProperties ost:maxOccurs ?maxOccurs } .
	?ostProperties ost:propertyDefinition ?propDefinition .
	?propDefinition ost:propertyName ?propName .
	OPTIONAL { ?propDefinition ost:propertyType ?propType } . }";

declare variable $REQUIRED-ELEMENTS-FROM-RDF-TYPE-SPARQL-TEMPLATE :=
"SELECT ?elementName ?elementNs ?elementType ?minOccurs ?maxOccurs ?propDef WHERE
{
  ?s a ost:RecordDefinition .
  ?s ost:rdfType 'incoming-rdf-type' .
  ?s ost:recordElement ?ostElement .
  OPTIONAL { ?ostElement ost:maxOccurs ?maxOccurs } .
  OPTIONAL { ?ostElement ost:minOccurs ?minOccurs } .
  ?ostElement ost:elementDefinition ?elementDefinition .
  ?elementDefinition ost:elementName ?elementName .
  ?elementDefinition ost:elementNs ?elementNs .
  OPTIONAL { ?elementDefinition ost:elementType ?elementType } .
  OPTIONAL { ?elementDefinition ost:propertyDefinition ?propDef }
}";

declare variable $PREDEFINED-RDF-TYPES-SPARQL-TEMPLATE :=
"SELECT ?rdfType WHERE
{
	?s a ost:RecordDefinition .
	?s ost:rdfType 'incoming-rdf-type' .
	?s ost:predefinedTypes ?predefinedTypes .
	?predefinedTypes ost:rdfType ?rdfType .
}";

declare variable $PREDEFINED-PROPERTIES-SPARQL-TEMPLATE :=
"
SELECT ?predefinedProp { ?s ost:rdfType 'incoming-rdf-type' . ?s ost:predefinedProperties ?predefinedProp }
";
(:declare variable $PREDEFINED-PROPERTIES-SPARQL-TEMPLATE :=
"SELECT ?predefinedProperties WHERE
{
	?s a ost:RecordDefinition .
	?s ost:rdfType 'incoming-rdf-type' .
	?s ost:predefinedProperties ?predefinedProperties .
}";:)

declare variable $SCHEMA-VALIDATION-SPARQL-TEMPLATE :=
"
SELECT ?elementName ?elementNs WHERE
{
  ?s a ost:RecordDefinition .
  ?s ost:rdfType 'incoming-rdf-type' .
  ?s ost:recordElement ?ostElement .
  ?ostElement ost:validate 'true' .
  ?ostElement ost:elementDefinition ?elementDef .
  ?elementDef ost:elementName ?elementName .
  ?elementDef ost:elementNs ?elementNs
}";

declare variable $RECORD-DEFINITION-RECORD-URI-FOR-INCOMING-TYPE :=
"
SELECT ?uri WHERE
{
	?s a ost:RecordDefinition .
	?s ost:rdfType 'incoming-rdf-type' .
	?s dc:identifier ?uri
}";

declare variable $API-CURIE := 'ost:Api';
declare variable $API-FULL-URI := 'http://rdf.overstory.co.uk/rdf/terms/Api';

declare variable $ELEMENT-NAME-CURIE := 'http://rdf.overstory.co.uk/rdf/terms/RdfElementMap';
declare variable $ELEMENT-NAME-FULL-URI := 'ost:RdfElementMap';

declare variable $OST-FULL-URI := 'http://rdf.overstory.co.uk/rdf/terms/';
