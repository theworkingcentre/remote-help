#!/bin/bash

# Lead a helper to initiate a remote VNC session. 
# Requires: tightvnc, pkill, x-terminal-emulator

# Paul "Worthless" Nijjar, 2014-09-03

# === Global Variables ====

CONFFILE="remote-help.conf"

ssh_pid=""

# === Procedures

# Echo debug messages if set 
decho () 
{
    if [ "$DEBUG_LEVEL" -gt 0 ] 
    then
        echo $1
    fi

    echo $1 >> $LOGFILE

} 

# Close it all down 
cleanup () 
{ 

    exitval="0"

    if [ "$#" -gt "0" ] 
    then
        exitval=$1
    fi
    decho "Cleaning up with exit value $exitval"

    if [[ -n $ssh_pid ]]
    then
        pkill --signal 9 -f "ssh -f .+ ${helper_id}@${SSH_HOST_HELPER}"
	retval=$?

	decho "Ran pkill with exit code $retval"
    
    fi

    decho "Goodbye!"

    exit $exitval

}


# === Main Program ====



# SIGHUP SIGINT SIGQUIT SIGBUS SIGPIPE SIGTERM
trap 'cleanup 1' 1 2 3 7 13 15  

source $CONFFILE || cleanup 1 

# The last two digits of the helper account

have_account="nope"
account_id="xx"

while [ "$have_account" != "y" ]
do
    printf 'Enter the account to use (01-%s): ' "$LAST_ACCOUNT"
    read account_id

    # I guess we should check whether this is in the right
    # range, huh?
    printf 'You entered account "%s". Is this correct? (y/n): ' "$account_id"
    read have_account
done

export helper_id="${HELPER_PREFIX}${account_id}"

decho "Volunteer is $helper_id"

decho 'Launching SSH session. Follow instructions!'

$XTERM -e "ssh -p $SSH_PORT ${helper_id}@${SSH_HOST_HELPER}" &


# printf '
# In a new terminal, enter the following command
# to allow remote access:
# =====================
# ssh -p %s %s@%s
# =====================
# Log in and follow the instructions. 
# ' "$SSH_PORT" "$helper_id" "$SSH_HOST_HELPER"

open_vnc="nope"

while [ "$open_vnc" != "y" ]
do
    printf "When the user has typed the access code and you 
    are ready to open a VNC connection, type y: "
    read open_vnc
    printf 'You entered "%s" \n' "$open_vnc"
done

printf '
====================
The first password is your SSH password
The second password is the VNC password given to you by your user
====================

If the screen gets garbled during the connection, press the left
<alt> key three times to redraw the screen.

'

remote_tunnelport=$(( $account_id + $VNC_BASE ))


ssh -f -p $SSH_PORT -N -L ${VNC_LOCALPORT}:localhost:${remote_tunnelport} ${helper_id}@${SSH_HOST_HELPER}
retval=$?
ssh_pid=$!

decho "$ssh_pid is \"$ssh_pid\", retval is \"$retval\""

if [ "x$retval" != "x0" ]
then
    decho 'It looks like SSH tunnelling failed. Bailing out.'
    cleanup 1
fi

#export VNC_VIA_CMD="/usr/bin/ssh -f -p $SSH_PORT -N -L %L:%H:%R $helper_id@%G sleep 20"
vncviewer -bgr233 -nojpeg "localhost::${VNC_LOCALPORT}"


cleanup 0

# vim: shiftwidth=4 tw=70 expandtab ai sm
