#!/bin/bash
# script to create ipsets and fill them with data from ipdeny.com
# has a offline mode to use last local copy
# https://github.com/binarybear-de/scripts
SCRIPTBUILD="BUILD 2022-05-21"

IPSET=/usr/sbin/ipset
NC='\033[0m'
wr_grn() { echo -e "\033[0;32m$1${NC}"; }
wr_ylw() { echo -e "\033[0;33m$1${NC}"; }
wr_red() { echo -e "\033[0;31m$1${NC}"; }

function do_fallback () {
	if [ -f "$etcdir/$1" ]; then
		cp $etcdir/$1 $tmpdir/$1
		wr_ylw "using local file"
		USE_LOCAL=1
		return 0
	else
		wr_red "no local copy found!"
		return 1
	fi
}

function update_ipset() {
	USE_LOCAL=0
	echo ""
	# create ipset if not existent
	echo "processing $1"
	$IPSET create $1 hash:net $2 -exist

	if ! [ "$param" = "offline" ]; then
		echo -n "download ... "
		wget -q -O $tmpdir/$1 --no-check-certificate "$3"
		if [ $? -eq 0 ];then
			wr_grn "OK"
		else
			wr_ylw "FAILED"

			# delete empty file from failed download
			if [ ! -s $tmpdir/$1 ] ; then rm $tmpdir/$1 ; fi

		        do_fallback $1
			if [ $? -ne 0 ] ; then	return 1 ; fi
		fi
	else
		# offline mode
	        do_fallback $1
		if [ $? -ne 0 ] ; then	return 1 ; fi
	fi

	if cmp -s "$tmpdir/$1" "$etcdir/$1"  && [ $USE_LOCAL -eq 0 ] ; then
		wr_grn "local copy up to date"
	else
		echo -n "reloading ... "

		# flush existing list
		$IPSET flush  $1

		# Add each IP address from the downloaded list into the ipset
		for i in $(cat $tmpdir/$1 ); do $IPSET -A $1 $i; done

		# move temporary download to persistent storage - ensures a working ipset after reboot
		if [ $USE_LOCAL -eq 0 ]; then mv $tmpdir/$1 $etcdir/$1 ; fi

		wr_grn "OK"
	fi
}

###############

tmpdir=/tmp/ipsets
etcdir=/etc/ipsets
mkdir -p $tmpdir
mkdir -p $etcdir
param=$1

###############


update_ipset de4 "family inet" "https://www.ipdeny.com/ipblocks/data/aggregated/de-aggregated.zone"
update_ipset de6 "family inet6" "https://www.ipdeny.com/ipv6/ipaddresses/aggregated/de-aggregated.zone"

update_ipset ru4 "family inet" "https://www.ipdeny.com/ipblocks/data/aggregated/ru-aggregated.zone"
update_ipset ru6 "family inet6" "https://www.ipdeny.com/ipv6/ipaddresses/aggregated/ru-aggregated.zone"
