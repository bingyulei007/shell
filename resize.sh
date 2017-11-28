#!/bin/bash
echo "start resize retention"

base_disk="/var/lib/openmetric/carbon-disk"
base_mem="/dev/shm/carbon-mem"
child_dir=("whisper/EPIC/sdn")
#一下三个参数对应child_dir数组的个数。
retention_disk0=("300s:1d" "600s:30d")
retention_mem0=("300s:5h")
aggregation_method0=max

function doresize(){
	echo "call doresize"
	local  _path=$1
	local _aggregation=$2
	local _retention=""
	echo $_path $_aggregation $#
	shift 2
	while [ "$#" -gt 0 ]; do
        _retention="$_retention  $1"
        shift
    	done

	if [[ -n $_path && -d $_path ]]
	then
	 for element in $(ls $_path)
	    do
			if test -d $_path/$element
			then
				doresize  $_path/$element $_aggregation $_retention
			else
				if [ "${element##*.}" = "wsp" ];then
					echo  " whisper-resize.py $_path/$element $_retention --aggregationMethod=$_aggregation"
					whisper-resize.py $_path/$element $_retention --aggregationMethod=$_aggregation
				fi
			fi		
	    done
	elif [[ -n $_path && -f $_path ]]; then
		if [ "${element##*.}" = "wsp" ];then
		echo  " whisper-resize.py $_path/$element $_retention --aggregationMethod=$_aggregation"
		whisper-resize.py $_path/$element $_retention --aggregationMethod=$_aggregation
		fi
	else
		echo "	qi gai de diayong "
	fi
}

function resize() {
	echo "call resize function"
	local  _path=$1
	local _type=$2
	local _aggregation=""
	local _retention=""

	if [[ -n $_path && -d $_path ]]
	then
		local _tempi=0
		for var in ${child_dir[@]}
		do

	 		if test -d $_path/$var
	 		then
	 			eval _aggregation=\${aggregation_method$_tempi}
	 			eval _arr=\${retention_$_type$_tempi[@]}
				for _tempretention in "${_arr[@]}"
			
	 			do
	 				_retention="$_retention $_tempretention"
	 			done
	   			doresize "$_path/$var" $_aggregation $_retention
		    	else
	   			echo "whisper not exit"
	 		fi
	 		_tempi=`expr $_tempi + 1`
		done
	else
		 echo "路径不存在"
	fi

}
resize "$base_mem" "mem"
resize "$base_disk" "disk"
