#!/bin/bash

#  Connect to remote help (vnc) server via an SSH tunnel, attempting to
#  keep things easy for the end user.
#  Copyright (C) 2014 Paul "Worthless" Nijjar

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.



# Depends: x11vnc, zenity, sshpass
# Currently the VNC password is stored in a file, which is awful.

# === Global Variables ====

CONFFILE="/etc/remote-help/get-remote-help.conf"

vnc_pid=""
ssh_pid=""

vnc_passfile=""

# === Procedures ====

# Close it all down 
cleanup () 
{ 

    exitval="0"

    if [ "$#" -gt "0" ] 
    then
        exitval=$1
    fi
    decho "Cleaning up with exit value $exitval"

    # Eliminate VNC password if it exists
    [[ -f $vnc_passfile ]] && rm -f $vnc_passfile

    [[ -n $ssh_pid ]] && kill $ssh_pid

    [[ -n $vnc_pid ]] && kill $vnc_pid

    # Kill x11vnc
    x11vnc -R stop
    pkill --signal 9 x11vnc

    # TODO: Kill zenity processes

    decho "Goodbye!"

    exit $exitval

}


# Echo debug messages if set 
decho () 
{
    if [ "$DEBUG_LEVEL" -gt 0 ] 
    then
        echo $1
    fi

    echo $1 >> $LOGFILE

} 

# === Main Program ====

decho "Logfile is $LOGFILE"

# SIGHUP SIGINT SIGQUIT SIGBUS SIGPIPE SIGTERM
trap 'cleanup 1' 1 2 3 7 13 15  

# There should be some more informative message here
source $CONFFILE || cleanup 1

# TODO: Check dependencies
# TODO: Zenity message if fail

# Override debug level
set DEBUG=0


keeptrying_ssh=0

while [ "$keeptrying_ssh" = "0" ]
do 
    
    sshpassphrase=`zenity --entry \
      --text="Please get the access password from your helper and
      type it here. (You will see the password as you type it.)" \
      --title="Server Access Password" `
    retval_accessq=$?


    decho "I think the return value of Server Access Password is $retval_accessq"

    if [ "$retval_accessq" = "0" ] 
    then 

        # The first two digits are the identifier of the 
        # account to use (eg 01 for helpme01).
        # The rest is the password. Let's hope that you do not 
        # have over 99 accounts.
        # Use this to set the VNC port too.

        CUSTOMER_SUFFIX=$(echo $sshpassphrase | cut -c 1-2)
        SSHPASS=$(echo $sshpassphrase | cut -c 3-)
        export SSHPASS

        SSH_USER="${CUSTOMER_PREFIX}${CUSTOMER_SUFFIX}"

        VNC_PORT=$((VNC_BASE + CUSTOMER_SUFFIX))

        decho "I think SSHPASS is $SSHPASS"
        decho "I think SSH_USER is $SSH_USER"
        decho "I think VNC_PORT is $VNC_PORT"


        # If no password is entered just try again (no prompt)
        if [ ! -z $SSHPASS ] 
        then 
            
            # Try password and open SSH connection.
            sshpass -e ssh -t -C -N -oStrictHostKeyChecking=no \
              -R ${VNC_PORT}:localhost:5900 \
              -p ${SSH_PORT} ${SSH_USER}@${SSH_HOST_CUSTOMER} &
            retval=$?
            ssh_pid=$!

            decho "I think SSH PID is $ssh_pid"

            # How do we tell whether the connection was successful?
            if [ "$retval" = "0" ] 
            then 
                keeptrying_ssh="1"
                decho "SSH connection successful, I think"
            elif [ -z "$retval" ] 
            then 
                decho "I think SSH was not run!"
                keeptrying_ssh="1"
            elif [ "$retval" = "5" ] 
            then
                keeptrying_ssh=`zenity --question \
                  --text="It appears that $SSHPASS is the wrong password.
                  Try again?"`
            fi # end if ssh was successful

        fi # end if SSHPASS not empty

    else 
        decho "I think the user cancelled entering in the SSH password"
        cleanup
    fi  # end if server access password is not cancelled

done  # end ssh loop


# If it works, proceed to open the VNC connection.

vnc_passcode=$RANDOM 
vnc_passfile=`mktemp`
echo $vnc_passcode > $vnc_passfile

decho "VNC passfile is in $vnc_passfile"

x11vnc -display :0 -passwdfile $vnc_passfile -ncache 10 -speeds modem \
 -nowirecopyrect -logappend $LOGFILE &

vnc_retval=$?
vnc_pid=$!

if [ "$vnc_retval" != "0" ]
then 
    decho "Uh oh. x11vnc failed with code $vnc_retval"
    cleanup 1
fi


vncaccesstext="To enable remote desktop sharing, please give your
helper the following passcode: <span size='x-large'>$vnc_passcode</span> 
Click the button to stop the session."

zenity --info --text="$vncaccesstext" \
  --title="Share your desktop" \
  --ok-label="End/prevent connection!"
retval_sharedesktop=$?


# Clean up
cleanup

# vim: shiftwidth=4 tw=70 expandtab ai sm
