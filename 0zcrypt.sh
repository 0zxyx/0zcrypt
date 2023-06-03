#!/bin/bash

function encrypt() {
	
	
	shred -zu $1.enc 2>/dev/null



	declare -a arr=()
	
	touch /tmp/.hgtk
	chmod 600 /tmp/.hgtk
	shuf -i 0-255 -n256 > /tmp/.hgtk

	i=-1

	while read dec;
	do
		hex=$(echo -n "$dec" | perl -ne 'printf("%02x", $_)')
		let "i=i+1"
		arr[$i]=$hex
	done < /tmp/.hgtk

	shred -zu /tmp/.hgtk 2>/dev/null


	fh=$(md5sum $1 |head -c 32)
	arr[256]=$fh

	fcc=$(wc -c < $1)
	
	inf=$(xxd -ps $1 | tr -d '\n')

	shred -zu /tmp/.out.h 2>/dev/null
	touch /tmp/.out.h
	chmod 600 /tmp/.out.h
	
	for i in `seq 0 $fcc`;do chr=${inf:$((2 * ${i})):2};
		for i in `seq 0 255` ; do
			dec=$(printf '%02x' $i);
			if [ "$chr" = "$dec" ];
			then
				echo -n ${arr[${i}]} >> /tmp/.out.h
			fi
		done
	done


	
	xxd -r -ps  < /tmp/.out.h > $1.enc
	
	shred -zu /tmp/.out.h 2>/dev/null

	echo -e "\e[1;33mEncrypted file: $1.enc\e[0m\n"


	echo -e "\e[1;36mEncrypted key: \e[0m\n"

	for i in {0..256};do echo -n ${arr[$i]};done


}

function decrypt() {



	echo -e "\e[1;36mEnter key to decrypt\e[0m\n"
	read key


	declare -a arr2=()
	
	for i in `seq 0 255`;
	do
		chr=$(echo $key | awk "{ printf substr( \$0, $((2 * $i + 1)), 2 ) }");
		arr2[$i]=$chr
	done



	inf=$(xxd -ps $1 | tr -d '\n')
	
	file=${1::-4}
	
	shred -zu /tmp/.out.dh 2>/dev/null
	touch /tmp/.out.dh
	chmod 600 /tmp/.out.dh
	shred -zu $file.dec 2>/dev/null
	
	fcc=$(wc -c < $1)
	for i in `seq 0 $fcc`;do chr=${inf:$((2 * ${i})):2};
		for i in `seq 0 255` ; do
			dec=$(printf '%02x' $i);
			if [ "$chr" = "${arr2[${i}]}" ];
			then
				echo -n "$dec" >> /tmp/.out.dh
			fi
		done
		
	done

	

	xxd -r -ps  < /tmp/.out.dh > $file.dec
	
	
	shred -zu /tmp/.out.dh 2>/dev/null
	
	fh2=$(echo $key | awk "{ printf substr( \$0, 513 , 32 ) }");

	md5sum --status -c <(echo $fh2 $file.dec)

	if [[ $? = 0 ]];
	then
		echo -e "\e[1;32mDecryption Sucess\e[0m\n"
	else
		echo -e "\e[1;31mDecryption Failed\e[0m\n"
	fi


	echo -e "\e[1;33mDecrypted file: $file.dec\e[0m\n"

}


if [ "$1" == "-e" ] && [ "$2" != "" ]
then
	if [[ ! -f "$2" ]];then echo -e "\e[1;31mFile does not exist\e[0m\n" ;exit ;fi
	encrypt $2
elif [ "$1" == "-d" ] && [ "$2" != "" ]
then
	if [[ ! -f "$2" ]];then echo -e "\e[1;31mFile does not exist\e[0m\n" ;exit ;fi
	decrypt $2
else
	echo
	echo '================================================================'
	echo
	echo '======================== Coded by 0zxyx ========================'
	echo
	echo '================================================================'
	echo
	echo -e "\e[1;36mSyntax $0 -e file \e[0m"
	echo -e "\e[1;36mSyntax $0 -d file.enc \e[0m"
fi


