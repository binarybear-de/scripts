Script to copy a proxmox backup server datastore to a external drive with LUKS encryption.

## Goal
I wanted to make one or more additional off-site-backups on encrypted USB-disks. Problem was that you can only create new datastores in proxmox, but not unmount or add existing ones. That can only be done manually in the /etc/proxmox-backup/datastore.cfg.\
Also calling the Sync script from the GUI every time was very annoying. After being done next problem shows up: If you try to unmount the disk without removing the datastore OS won't do that, because the disk is in use by PBS. Lazy-Unmounting will work, but creates a spammed syslog, that the datastore is inaccessable. So only way is to remove the datastore and then unmount safely.
All those steps (including automatic mounting and opening LUKS partition via LUKS_LABEL) are now automated on this script

## Features
* Mounts an encrypted LUKS drive / partition identified by the LUKS_LABEL
* adds the datastore in Proxmox Backup Server
* syncs an existing datastore to it
* removed datastore vom PBS and unmounts the drive
* HDD spindown via hdparm

## Requirements 
* Proxmox Backup Server
* existing backup datastore
* target backup datastore on a LUKS encrypted disk (read below)

## Installation / Setup

### One-liner
The I-am-lazy-just-install method: Just copy-paste the whole block in the shell on Debian-based systems
```
wget https://raw.githubusercontent.com/binarybear-de/scripts/main/pbs-luks-sync/pbs-luks-sync.sh -O /usr/local/bin/pbs-luks-sync \
&& chmod +x /usr/local/bin/pbs-luks-sync \
&& wget https://github.com/binarybear-de/scripts/blob/main/pbs-luks-sync/pbs-sync.cfg -O /etc/pbs-sync.cfg \
&& chmod 700 /etc/pbs-sync.cfg \
&& chown root: /etc/pbs-sync.cfg
```

### updating
```
wget https://raw.githubusercontent.com/binarybear-de/scripts/main/pbs-luks-sync/pbs-luks-sync.sh -O /usr/local/bin/pbs-luks-sync
&& chmod +x /usr/local/bin/pbs-luks-sync \
```

### manual
* Move the ```pbs-luks-sync.sh``` into the local-bin dir as ```/usr/local/bin/pbs-luks-sync``` and make it executable
* Move the ```unifi.cfg``` config file into etc dir as ```/etc/pbs-sync.cfg```
* Set permissions of ```pbs-sync.cfg``` to 700 with owner root

### setup
FIXME
