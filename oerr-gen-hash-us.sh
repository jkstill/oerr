#!/usr/bin/env bash

cat <<-EOF > oraus.hash
\$errMsg = {
  us => {
EOF

tmpfile=$(mktemp)

for facility in $(./oerr-gen-hash.pl -h | grep -E '^\s+[[:alpha:]]+:' | cut -f1 -d:| tr -d ' ')
do
	./oerr-gen-hash.pl $facility us | tail -n +3 > $tmpfile
	lc=$(wc -l $tmpfile | awk '{print $1}')
	head -n $((lc-2)) $tmpfile 
	echo ','
done >> oraus.hash

cat <<-EOF >> oraus.hash
	}
} 
EOF

rm -f $tmpfile


