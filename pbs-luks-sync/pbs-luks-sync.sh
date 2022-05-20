#!/bin/bash
# script to mount a LUKS volume and a datastore and sync that with another datastore in proxmox
# https://github.com/binarybear-de/scripts
SCRIPTBUILD="BUILD 2022-05-21"

RED='\033[0;31m'
YEL='\033[0;33m'
green='\033[0;32m'
NC='\033[0m'

# source configuration - set your parameters in this config file:
. /etc/pbs-sync.cfg

wr_grn() { echo -e "\033[0;32m$1${NC}"; }
wr_ylw() { echo -e "\033[0;33m$1${NC}"; }
wr_red() { echo -e "\033[0;31m$1${NC}"; }

do_mount() {

##########
#	pre-checks
##########

	echo -n "check if any disk with label is present ... "
	if ! lsblk -f | grep -wqs $DISK_LABEL ; then
		wr_red "disk $DISK_LABEL is not present!"
		exit 1
	else
		wr_grn "OK"
	fi

	echo -n "check if target folder does not exists ... "
	if ! [ -d "$LUKS_MOUNTPOINT" ]; then
		wr_ylw "mountpoint does not exist - creating $LUKS_MOUNTPOINT"
		mkdir -p $LUKS_MOUNTPOINT
	else
		wr_grn "OK"
	fi

	echo -n "check if already mounted ... "
	if grep -qs $LUKS_MOUNTPOINT /proc/mounts; then
		wr_ylw "mountpoint is in use"
#		do_unmount
		return
	else
		wr_grn "OK"
	fi

	echo -n "check if already existing LUKS mount ... "
	if [ -f /dev/mapper/$LUKS_LABEL ]; then
		wr_ylw "LUKS \"$LUKS_LABEL\" is already open"
#		do_unmount;
		return
	else
		wr_grn "OK"
	fi

##########
#	mounting backup
##########

	# setting trap to dismount if script fails or ends..
	trap do_unmount SIGHUP SIGKILL SIGTERM SIGINT

	echo -n "try to mount LUKS drive ... "
	if ! echo "$LUKS_PASSWORD" | cryptsetup open /dev/disk/by-label/$DISK_LABEL $LUKS_LABEL; then
		wr_red "LUKS unlock failed!"
	else
		wr_grn "OK"
	fi

	if ! mount /dev/mapper/$LUKS_LABEL $LUKS_MOUNTPOINT; then
		echo -e "Mounting LUKS failed!"
		exit 1
	fi

}
do_backup() {
	echo -e "\ndatastore: $DATASTORE_USBDRIVE\n\tpath $LUKS_MOUNTPOINT$SUBFOLDER" >> /etc/proxmox-backup/datastore.cfg

	echo -n "starting backup ..."
	proxmox-backup-manager pull $REMOTE $DATASTORE_INTERNAL $DATASTORE_USBDRIVE --remove-vanished false
	wr_grn "OK"
}

do_unmount() {

	sleep 1
	echo -n "remove datastore ... "
	if grep -qs "datastore: internal" /etc/proxmox-backup/datastore.cfg; then
		if ! proxmox-backup-manager datastore remove $DATASTORE_USBDRIVE --keep-job-configs yes > /dev/null; then
			wr_red "PBS unmount failed!"
		else
			wr_grn "OK"
		fi
		sleep 1
	fi

	echo -n "unmounting filesystem ... "
	if ! output=$(umount $LUKS_MOUNTPOINT); then
		wr_red "output is $output"
		wr_red "unmounting failed - FORCE!"
		umount $LUKS_MOUNTPOINT -l
	else
		wr_grn "OK"
	fi

	sleep 1

	echo -e -n "closing LUKS ...${RED} "
	if ! cryptsetup close $LUKS_LABEL; then
		wr_red "closing LUKS failed!"
	else
		wr_grn "OK"
	fi

	unset PBS_REPOSITORY
}

###############

case "$1" in
	"")
		do_mount
		do_backup
		do_unmount
	;;
	open)
		do_mount
	;;
	close)
		do_unmount
	;;
	*)
		echo "wrong parameter. Use \"open\", \"close\" or none"
	;;
esac
