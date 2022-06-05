#!/bin/bash
MAIL=mail@example.org

if [ $1 ]; then
        /usr/sbin/pvesm set pbs --disable 0
        sleep 3

        vzdump --mailto $MAIL --mailnotification failure --pool $1 --storage pbs --all 0 --mode snapshot --notes-template "{{guestname}}"
        RESULT=$?
        /usr/sbin/pvesm set pbs --disable 1
else
        echo "need a pool!"
        RESULT=1
fi
exit $RESULT
