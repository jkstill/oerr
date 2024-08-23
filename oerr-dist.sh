#!/usr/bin/env bash

zipFile=oerr-dist.zip

zip $zipFile oerr.pl *.msg && cp $zipFile  /mnt/zips/tmp/oracle/

echo "Created $zipFile"

echo "copied to /mnt/zips/tmp/oracle/$zipFile"




