#!/bin/bash

service=$1

identifier=$(awk '/about="(.*)"/' api/api.xml | cut -c9-100 | rev | cut -c2-100 | rev)
endpoint="${service}/record/id/${identifier}"

curl -f -X PUT ${endpoint} -H "Content-Type: text/xml" -d '@api/api.xml' --user ${user}:${passwd}

