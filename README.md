VNC Remote Help Scripts
=======================

These are a set of scripts that permit customers who need remote help
to share their desktops with trusted helpers in a semi-secure way.

### Goals 

- Minimize hassle for customers while protecting their security
- Keep bandwidth use small, even at the expense of user experience
- Require no port forwarding for either the customer or volunteer
  computers. Instead, use an SSH server on the Internet that both
  groups can log into. 
- Lock down access to the SSH server by unlocking and relocking 
  customer accounts as required.
- Use temporary passwords that are regenerated each session
- Only allow access to customer machines if the customers explicitly
  allow it (ie there should be no backdoors)


### Assumptions

- People with access to the helper accounts can be trusted, because
  they get passwordless sudo access to usermod and chpasswd

### Overview

- The customer initiates a connection from his or her desktop computer. 
  This prompts the customer for a (numerical) password.
- The technician SSHes into the SSH server. This unlocks a customer 
  account and assigns a numerical password to this account.
- The technician reads the numerical password to the customer.
- The customer types in the numerical password, which creates an 
  SSH tunnel to the SSH server. x11vnc tunnels through this SSH 
  server, and sets a second numerical passcode to allow access
  to the session.
- The technician now makes a second connection to the SSH server to 
  connect to the customer VNC session. The technician is first prompted
  for the SSH account password, and then is prompted for the 
  VNC password.
- If the technician connects successfully, then the desktop is shared 
  and usable by either user.
- The customer has the ability to end the session at any time by 
  pressing a big "Close Connection" button.
- When the technician is done, he or she closes their first SSH session.
  This locks the customer account again, so the customer cannot 
  reconnect (without going through the process again). If for some 
  reason the technician does not lock the account, then the account
  should auto lock in two days.

It should be apparent that having a VNC session alone is not sufficient 
for this interaction to work. The technician has to interact with the 
customer in some other way (presumably by phone, although I guess
some chat client would work as well). 

### Weaknesses: 

- Setting login shells to shell scripts is a terrible idea and does
  not offer any more security than giving those users shell access.
- 256 colour output is ugly.
- Helpers need to enter too many passwords too many times, and in
  particular have to remember to enter the SSH password and VNC
  password in the correct sequence. This is a big pain. The solution
  is to use SSH keys for the helpers.
- The helper script does not validate input of the account number.

### Future Work

- Set up corresponding Windows scripts. Allowing the helpers to use
  Windows should not be difficult. Allowing the customers to use
  Windows will require making new get-remote-help.sh scripts. 
- Better error checking for missing dependencies
- Better input validation
- Allow more than 100 accounts (00-99?) 

Initial server setup
--------------------

Assume 10.10.10.x is the LAN subnet where helpers live

Install the unlock-customer-account.sh script on the server
- /usr/local/bin/unlock-customer-account.sh
- /etc/remote-help/remote-help.conf


Allow passwordless sudo access to unlock_accounts for following
commands:
- usermod
- chpasswd

In /etc/sudoers

    %unlock_accounts ALL = NOPASSWD: /usr/sbin/usermod /usr/sbin/chpasswd

In /etc/ssh/sshd_config:

    PermitTunnel yes
    AllowTcpForwarding yes
    AllowUsers helpme??  volunteer??@10.10.10.*
    PermitRootLogin no


Adding more user accounts
-------------------------

- Create helper account
- Set shell to /usr/local/bin/unlock-customer-account.sh
  usermod -s /usr/local/bin/unlock-customer-account.sh volunteer02

- Add corresponding helpme account
- Set shell to /bin/false


On client machines
------------------

apt-get install zenity sshpass x11vnc bash

/usr/share/pixmaps/get-remote-help.png
/usr/local/bin/get-remote-help.sh
/etc/remote-help/remote-help.conf
/usr/share/applications/get-remote-help-local.desktop


On helper machine
-----------------

Just make sure the following scripts are available in the same folder:

- setup-technician-remote-connection.sh
- remote-help.conf 


Credits
-------

- <https://openclipart.org/detail/3945/message-in-a-bottle> for the
  bottle icon 
- Members of <http://kwlug.org> community for suggestions and insight
