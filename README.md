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


### Weaknesses: 

- Setting login shells to shell scripts is a terrible idea and does
  not offer any more security than giving those users shell access.
- 256 colour output is ugly.
- Helpers need to enter too many passwords too many times, and in
  particular have to remember to enter the SSH password and VNC
  password in the correct sequence. This is a big pain. The solution
  is to use SSH keys for the helpers.

### Future Work

- Set up corresponding Windows scripts. Allowing the helpers to use
  Windows should not be difficult. Allowing the customers to use
  Windows will require making new get-remote-help.sh scripts. 


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