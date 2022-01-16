#!/bin/bash +e

############################################################################
# Stage 0 - variables init
############################################################################

_VMID=$(pvesh get /cluster/nextid) # set next available ID as a preference
_UNPRIV=1
_TMPL="debian-11-standard_11.0-1_amd64.tar.gz"
_STORAGE=ssd
_SIZE=1
_CORES=2
_MEM=1024
_BRIDGE=vmbr7
_IP=dhcp
_GW=10.234.7.1


############################################################################
# Stage 1 - Ask the Parameters for Deployment
############################################################################

read -p "ID [$_VMID]: "                 VMID
: ${VMID:=$_VMID}

_HOSTNAME="PCT$VMID"

read -p "Hostname [$_HOSTNAME]: "       HOSTNAME
: ${HOSTNAME:=$_HOSTNAME}

read -p "Unpriviledged [$_UNPRIV]: "    UNPRIV
: ${UNPRIV:=$_UNPRIV}

echo ""
echo "Available Templates"
echo "$(ls /var/lib/vz/template/cache | grep debian)"
echo ""

read -p "Template: [$_TMPL] "           TMPL
: ${TMPL:=$_TMPL}

read -p "Storage: [$_STORAGE] "         STORAGE
: ${STORAGE:=$_STORAGE}

read -p "Root size: [$_SIZE] "          SIZE
: ${SIZE:=$_SIZE}

read -p "Cores: [$_CORES] "             CORES
: ${CORES:=$_CORES}

read -p "RAM: [$_MEM] "                 MEM
: ${MEM:=$_MEM}

echo ""
echo "Available Interfaces"
echo "$(ls /sys/class/net | grep vmbr)"
echo ""


read -p "VM-Bridge: [$_BRIDGE] "        BRIDGE
: ${BRIDGE:=$_BRIDGE}

read -p "IP: [$_IP] "                   IP
: ${IP:=$_IP}

if ! [ $IP == "dhcp" ]; then
        read -p "Gateway: [$_GW]"       GW
        : ${GW:=$_GW}
        GW=",gw=$GW"
fi

############################################################################
# Stage 2 - Create the container
############################################################################

COMMAND="pct create $VMID /var/lib/vz/template/cache/$TMPL --unprivileged $UNPRIV --onboot $ONBOOT --arch amd64 --hostname $HOSTNAME --cores $CORES --memory $MEM --swap 0 --storage $STORAGE --net0 name=eth0,bridge=$BRIDGE$GW,ip=$IP,type=veth --rootfs $STORAGE:$SIZE,mountoptions=noatime --features nesting=1"

echo ""
echo "Command to create container: $COMMAND"
read -r -p "Create? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        $COMMAND
        ;;
    *)
        echo "Canceled."
        exit 1
        ;;
esac

############################################################################
# Stage 3 - Setup of things in the container
############################################################################

pct start $VMID

read -r -p "Execute install.sh? [y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
        $COMMAND
        ;;
    *)
        echo "Canceled."
        exit 1
        ;;
esac

echo "starting $VMID"...
sleep 5
pct exec $VMID -- bash -c "wget https://deploy.vmw5.de/install.sh &&\
bash install.sh &&\
rm install.sh"
