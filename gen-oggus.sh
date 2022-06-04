#!/usr/bin/env bash

for emsg in $(seq -w 0 50000 )
do
		
	declare errText=$(/u01/app/ogg/oggerr $emsg)

	[[ -n $errText ]] && {
		echo "$errText"
	}

done | tee oggus.msg

