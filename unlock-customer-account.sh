#!/bin/sh

# Allow a helper to SSH into the relay server and set up a VNC
# connection. 

# This should be run as the login script for the helper?
# The helper uses SSH to connect in and then the connection opens.

# Paul "Worthless" Nijjar, 2014-09-03

# Depends: passwordless sudo access to chpasswd, passwd

# === Global Variables ====

CONFFILE=/etc/remote-help/remote-help.conf

# Can I do this here?
source $CONFFILE || cleanup 1

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

    # Disallow helper account from connecting
    if [ "x$ssh_user" != "x" ] 
    then
        decho "Locking $ssh_user account"
        sudo usermod -e 1 $ssh_user
	sudo usermod -L $ssh_user
    fi

    decho "Goodbye!"

    exit $exitval

}


# === Main Program ====

decho "Logfile is $LOGFILE"


# SIGHUP SIGINT SIGQUIT SIGBUS SIGPIPE SIGTERM
trap 'cleanup 1' 1 2 3 7 13 15  

# The last two digits of the helper account should be 
# associated with the helpme account
me=$(whoami)

# Weird. dash wants tail -c 3, not 2 to get the last two chars.
account_id=$(whoami | tail -c 3)
export ssh_user="${CUSTOMER_PREFIX}${account_id}"

decho "ssh_user is $ssh_user"

# Set password on helper account
# Does this unlock the account automatically?
newpassword=$(/usr/bin/hexdump -n 2 -e '/2 "%u"' /dev/urandom)
decho "New password is $newpassword"
passwordstring="$ssh_user:$newpassword"
echo $passwordstring | sudo chpasswd 
retval=$?

if [ "$retval" -gt "0" ]
then 
    decho "Uh oh! Changing password failed with exit code $retval";
    cleanup 1
fi


# Enable helpme account for one day
timenow=`date +%s`
expiretime=$(($timenow + $ACCOUNT_DURATION))
decho "Expire time: $expiretime"
expirestring=`date --date="@$expiretime" +%F`
decho "Unexpiring account $ssh_user until $expirestring"
sudo usermod -e $expirestring $ssh_user
retval=$?

if [ "$retval" -gt "0" ]
then 
    decho "Uh oh! Unexpiring account failed with exit code $retval";
    cleanup 1
fi



# Unlock account
sudo usermod -U $ssh_user
retval=$?

if [ "$retval" -gt "0" ]
then 
    decho "Uh oh! Unlocking account failed with exit code $retval";
    cleanup 1
fi

accesscode="${account_id}${newpassword}"
vnc_port=$(($VNC_BASE + $account_id))

outputstring="
===========================
Accesscode: $accesscode
===========================
Please do the following: 
- Tell the user this access code
- Get him or her to type the code into the dialog box
- Get him or her to read the code back to you before pressing enter.

Once the user has opened a connection:
- proceed with the setup-technician-remote-connection script 
  (or manually make an SSH tunnel to port $vnc_port and connect your 
  VNC viewer to this tunnel)
- get the user to read the VNC passcode to you
- type it in and connect

"

printf '%s\n' "$outputstring"



# WHILE LOOP TIME

is_done="nope"

while [ "$is_done" != "done" ]
do
    printf 'Type "done" to close the connection.\n'
    read is_done
    printf 'You entered "%s"\n' "$is_done"
done

cleanup 

# vim: shiftwidth=4 tw=70 expandtab ai sm
