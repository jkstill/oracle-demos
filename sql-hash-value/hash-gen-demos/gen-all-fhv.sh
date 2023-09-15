#!/usr/bin/env bash

sepline='##############################################################'
sepsec='###'

sqldir=$1

[[ -z $sqldir ]] && {
	echo
	echo please supply a directory
	echo Directory name must not include the '-' character
	echo
	exit 1
}

for sqlfile in $sqldir/*.txt
do

	echo $sepline
	echo "$sepsec $sqlfile"
	echo $sepline

	./gen-fhv.sh $sqlfile

done


