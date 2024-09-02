#!/usr/bin/env bash

rm oerrs.exe ;  GOOS=windows GOARCH=amd64 go build -o oerrs.exe && file oerrs.exe

rm oerrs ;  GOOS=linux GOARCH=amd64 go build -o oerrs && file oerrs

./oerrs 6502 && cp oerrs.exe /mnt/zips/tmp/oracle/oerr-dist

