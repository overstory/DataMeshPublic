#!/bin/sh

service=$1
endpoint="${service}/record/id/"

for doc in *.xml ; do
	identifier=$(awk '/about="(.*)"/' $doc | tr -d '\040\011\012\015')
	size=`expr ${#identifier} - 2`
	revsize=`expr ${#identifier} - 9`
	identifier=$( echo $identifier | cut -c -$size | rev | cut -c -$revsize | rev )
	
	echo "Loading" $identifier

	curl -f -X PUT -d "@$doc" --header "Content-Type:application/xml" $endpoint$identifier
done
