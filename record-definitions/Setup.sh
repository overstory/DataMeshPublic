#!/bin/bash
echo "Start of DataMesh script."
echo " "
echo "This script will load required records for the DataMesh REST API."
echo "Please edit Setup.sh to change NetKernel location and credentials."
echo " "

dmhost="localhost"
dmport="8080"
dmuser="admin"
dmpasswd="admin"

dmservice="http://${dmuser}:${dmpasswd}@${dmhost}:${dmport}/datamesh"

echo "Service: ${dmservice}"

echo " "

echo "Loading prefixes to ${dmservice}..."

if ( ( cd prefixes ; sh ./load-prefixes.sh "$dmservice" ) ) ; then
	echo "Prefixes loaded ok"
else
	echo "*** Cannot load prefixes"
	exit 1
fi

echo " "

echo "Loading record definitions to ${dmservice}..."

if ( ( cd record-definitions ; sh ./load-definitions.sh "$dmservice" ) ) ; then
	echo "Record definitions loaded ok"
else
	echo "*** Cannot load record definitions"
	exit 1
fi

echo " "

echo "Loading prefix record definitions to ${dmservice}..."

if ( ( cd record-definitions-prefix ; sh ./load-definitions.sh "$dmservice" ) ) ; then
	echo "Prefix record definitions loaded ok"
else
	echo "*** Cannot load record definitions"
	exit 1
fi

echo " "

echo "Loading rdf element map record definitions to ${dmservice}..."

if ( ( cd record-definitions-rdf-element-map ; sh ./load-definitions.sh "$dmservice" ) ) ; then
	echo "Rdf element map record definitions loaded ok"
else
	echo "*** Cannot load record definitions"
	exit 1
fi

echo " "

echo "Loading property definitions to ${dmservice}..."

if ( ( cd property-definitions ; sh ./load-definitions.sh "$dmservice" ) ) ; then
	echo "Property definitions loaded ok"
else
	echo "*** Cannot load property definitions"
	exit 1
fi

echo " "

echo "Loading element definitions to ${dmservice}..."

if ( ( cd element-definitions ; sh ./load-definitions.sh "$dmservice" ) ) ; then
	echo "Element definitions loaded ok"
else
	echo "*** Cannot load element definitions"
	exit 1
fi

echo " "

echo "Loading the API settings to ${dmservice}..."

if ( sh ./api/load-api.sh "$dmservice" ) ; then
	echo "API loaded ok"
else
	echo "*** Cannot load API"
	exit 1
fi

echo " "

echo "Loading RDF element maps to ${dmservice}..."

if ( ( cd rdf-element-maps ;  sh ./load-maps.sh "$dmservice" ) ) ; then
	echo "RDF element maps loaded ok"
else
	echo "*** Cannot load RDF element maps"
	exit 1
fi

echo " "
echo "End of DataMesh script."
