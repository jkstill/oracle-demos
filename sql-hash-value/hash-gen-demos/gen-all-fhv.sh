#!/usr/bin/env bash

sepline='##############################################################'
sepsec='###'

for sqlfile in sqlfiles/*.txt
do

	echo $sepline
	echo "$sepsec $sqlfile"
	echo $sepline

	./gen-fhv.sh $sqlfile

done


