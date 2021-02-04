#!/usr/bin/env bash


declare PID=$1

: ${PID:?Please supply PID}

[[ "$PID" =~ ^[0-9]+$ ]] || {
	echo
	echo $PID is not numeric
	echo 
	exit 1
}


 
echo Recording:

perf record -F 999 -T -g --timestamp-filename  -p $PID


