#!/bin/bash

service=$1
endpoint="${service}/rdf/prefix"

echo "Endpoint: $endpoint"

cat prefixes.txt | while read -a fields
	do
		echo "Loading ${fields[0]}=${fields[1]}..."
		curl -f --request PUT "${endpoint}/${fields[0]}" -d "${fields[1]}" -H "Content-Type: text/plain"
	done

