#!/usr/bin/env bash

hex_to_num () {
	local hexnum="$1"
	#echo "hexnum: $hexnum"
	printf "%d" $((16#$hexnum))
}

# oracle is using the last 4 bytes of the full_hash_value(hex) to generate the hash_value (number)
fhv_to_hash_value () {
	local fhv="$1"
	hex_to_num ${fhv:24:8}
}

# expecting 8 character string - 4 bytes hex
endian_4 () {
	local hexstr="$1"

	local whash="$1"

	declare -a md5parts

	whash[0]=${hexstr:0:2}
	whash[1]=${hexstr:2:2}
	whash[2]=${hexstr:4:2}
	whash[3]=${hexstr:6:2}

	declare new_hex

	for i in {3..0}
	do
		declare tmp=${hexstr[$i]}
		#echo "i: $i  $tmp"
		new_hex="$new_hex"${whash[$i]}
	done

	echo $new_hex
}

md5_to_fhv () {
	local md5="$1"

	declare -a md5parts

	md5parts[0]=${md5:0:8}
	md5parts[1]=${md5:8:8}
	md5parts[2]=${md5:16:8}
	md5parts[3]=${md5:24:8}

	declare new_fhv

	#echo "md5_to_fhv: $md5"

	for i in {0..3}
	do
		declare tmp=${md5parts[$i]}
		#echo "i: $i  $tmp"
		for j in {3..0}
		do
			new_fhv="$new_fhv"${tmp:((j*2)):2}
		done
	done

	echo $new_fhv

}

md5_to_sqlid () {
	local md5="$1"

	declare -a sqlid_map=(
		 [0]='0'	 [1]='1'	 [2]='2'	 [3]='3'	 [4]='4'	 [5]='5'	 [6]='6'	 [7]='7'
		 [8]='8'	 [9]='9' [10]='a' [11]='b' [12]='c' [13]='d' [14]='f' [15]='g'
		[16]='h' [17]='j' [18]='k' [19]='m' [20]='n' [21]='p' [22]='q' [23]='r'
		[24]='s' [25]='t' [26]='u' [27]='v' [28]='w' [29]='x' [30]='y' [31]='z'
	);

	#echo
	#for i in ${!sqlid_map[@]}
	#do
		#echo "i: $i  ${sqlid_map[$i]}"
	#done

	# SQL ID generated from the last 8 bytes
	#md5: F0948CD09AA0DE41DFE9EF016C324700
	#md5 part 1: DFE9EF01
	#md5 part 2: 6C324700

	declare h1=${md5:16:8}
	declare h2=${md5:24:8}

	#echo
	#echo "h1: $h1"
	#echo "h2: $h2"

	declare hn1=$(endian_4 $h1)
	declare hn2=$(endian_4 $h2)

	#echo "hn1: $hn1"
	#echo "hn2: $hn2"

	declare n1=$(hex_to_num $hn1)
	declare n2=$(hex_to_num $hn2)

	#echo "n1: $n1"
	#echo "n2: $n2"

	declare hv
	(( hv = n1 * 4294967296 + n2 ))

	declare sql_id

	for i in {1..13}
	do
		(( r = ( hv % 32 ) +1 ))

		#echo "hv: $hv"
		#echo "r: $r"
		sql_id=${sqlid_map[r-1]}${sql_id}
		(( hv = hv/32 ))
	done

	echo $sql_id
}

##########
## main ##
##########

# get the md5 from a file

declare sqlfile=${1:?'Please specify a file'}

[ -r "$sqlfile" ] || {

	echo
	echo cannot open "$sqlfile"
	echo
	exit 1

}

# sqlid should be the filename - sqlfiles/cabd9827dc032-SCHEMA.txt

declare real_sqlid
declare schema=''

#if [[ "$sqlfile" =~ sqlfiles/[[:alnum:]]{13}-[[:alnum:]]+.txt ]]; then
if [[ "$sqlfile" =~ [[:alnum:]_]+/[[:alnum:]]{13}-[[:alnum:]_]+.txt ]]; then
	#echo processing schema
	real_sqlid=$(echo $sqlfile | cut -f2 -d\/ | cut -f1 -d- )
	schema=$(echo $sqlfile | cut -f2 -d- | cut -f1 -d\.)
else
	real_sqlid=$(echo $sqlfile | cut -f2 -d\/ | cut -f1 -d\. )
fi

echo " sql_id: $real_sqlid"
echo " schema: $schema"


declare md5 gen_fhv tmpSqlFile nullsAdded sqlID
declare matched=0

# try up to 5 nulls, first attempt without null
for x in 0 1 2 3 4 5
do

	tmpSqlFile=$(mktemp);
	cat $sqlfile > $tmpSqlFile

	[[ $x -ge 0 ]] && {
		for y in $(seq 1 $x )
		do
			#echo "    adding null"
			echo -en "\x00" >>  $tmpSqlFile
		done
	}

	md5=$(md5sum "$tmpSqlFile" | awk '{ print $1 }')
	rm -f $tmpSqlFile


	gen_fhv=$(md5_to_fhv $md5)
	hash_value=$(fhv_to_hash_value $gen_fhv)
	sqlID=$(md5_to_sqlid $md5)

	nullsAdded=$x
	if [ "$real_sqlid" == "$sqlID" ]; then
		matched=1	
		break
	fi

done

#echo "matched:$matched"

if [ $matched -eq 1 ]; then
	echo "         new generated fhv: $gen_fhv"
	echo "  new generated hash_value: $hash_value"
	echo "      new generated sql_id: $sqlID"
	echo "               nulls added: $nullsAdded"
else
	echo "  Failed to generate correct SQL_ID"
	echo "               nulls added: $nullsAdded"
fi





