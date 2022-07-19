#!/bin/bash
# script to enable a backup storage and execute backup.
# pretty much the same as in proxmox but this can to pre- and post actions like enable and disable the storage
# https://github.com/binarybear-de/scripts
SCRIPTBUILD="BUILD 2022-07-19"

MAIL=mail@example.org

if [ $1 ]; then

        # <pre-script>
        /usr/sbin/pvesm set pbs --disable 0
        sleep 3
        # </pre-script>

        vzdump --mailto $MAIL --mailnotification failure --pool $1 --storage pbs --all 0 --mode snapshot --notes-template "{{guestname}}"
        RESULT=$?
        
        # <post-script>
        /usr/sbin/pvesm set pbs --disable 1
        # </post-script>
else
        echo "need a pool!"
        RESULT=1
fi
exit $RESULT
