#!/bin/sh
#
# (c) Copyright Jimmy Vance
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    ( http://www.fsf.org/licenses/gpl.txt )

# First Release: December 2005
# Update Release: March 2006
#
#    This script is loosely based on code originally by Wolfgang Fuschlberger. 
#    Wolfgang's original code is available on his web site at 
#    http://www.fuschlberger.net/programs/ssh-scp-chroot-jail/
#
# Features:
#	 - Creates chroot-jail using pam_chroot.so module
#	 - Uses /home/jail/ as 'base' for users'
#	 - Places jailed users' $HOMEs in /home/jail/$CHROOT_USERNAME/home/
#	 - Provides shell, scp, sftp, and rsync 
#
#    Main differences between the two $DISTRO sections of the script
#    location of sftp-server is different
#    ldd does not get all the needed library files.
#
#    This version of the script has been tested on: 
#      Red Hat Enterprise Linux 4 Update 2 
#      SuSE Linux Enterpise Server 9 Service Pack 3
#
#    It should work on others with slight modifications.
#    I've noticed variances in some of the library files versions with updates
#
#
# USAGE:
# make_chroot_jail.sh username password
# 
# OTPTIONALLY:
# make_chroot_jail.sh username password shell
#
################################################################################

if [ "$UID" -ne "0" ];
    then
      echo "Error: You must be root to run this command." >&2
    exit 1
fi

# Check existence of necessary files
echo -n "Checking distribution... " 
if [ -f /etc/SuSE-release ];
    then
	echo "Supported Distribution found"
	echo -e "System is running SuSE Linux\n"
	DISTRO=SUSE;
    elif [ -f /etc/redhat-release ];
    then 
	echo "Supported Distribution found"
	echo -e "System is running Red Hat Linux\n"
	DISTRO=REDHAT;
    else 
	echo -e "failed...........\nThis script only works on Red Hat and SuSE Linux!\n"
    exit 1
fi
 
# Specify the apps you want to copy to the jail

APPS="/bin/bash /bin/cp /usr/bin/dircolors /bin/ls /bin/mkdir /bin/mv /bin/rm /bin/rmdir /bin/sh /usr/bin/id /usr/bin/rsync /usr/bin/ssh /usr/bin/scp /usr/bin/rsync /sbin/unix_chkpwd"

if [ $DISTRO = SUSE ];
    then 
	APPS="$APPS /usr/bin/netcat /usr/lib/ssh/sftp-server"
    elif [ $DISTRO = REDHAT ];
    then 
	APPS="$APPS /usr/bin/nc /usr/libexec/openssh/sftp-server"
fi

# Check if we are called with username or update
if [ -z "$1" ];
    then    
	echo
        echo -e "Error: Parameter missing, probably forgot to enter the username and password\n"
	echo -e "  Creating new chrooted account:"
        echo -e "  Usage: $0 username password"
	echo -e "  or specify \$SHELL:"
        echo -e "  Usage: $0 username password /bin/bash"
	echo -e "  Updating files in the chroot-jail:"
        echo -e "  Usage: $0 update\n"
	echo -e "  To uninstall: # userdel \$USER"
        echo -e "                # rm -rf /home/jail/$USER\n"
    exit
fi

# Check existence of necessary files
echo -n "Checking for chroot... " 

if [ `which chroot` ];
    then 
	echo "OK";
    else
	echo -e "failed\nPlease install chroot-package/binary!\n"
    exit 1
fi

# specify username and jail path

CHROOT_USERNAME=$1
CHROOTDIR=/srv/home2/jail/${CHROOT_USERNAME}

# Create directories in jail
# users will be created under this directory structure

JAILDIRS="dev etc/pam.d etc/security bin home sbin usr/bin usr/lib/ssh usr/libexec/openssh var var/log var/run"
for directory in $JAILDIRS ;
    do
	if [ ! -d "${CHROOTDIR}/$directory" ];
	then
	    mkdir -p "${CHROOTDIR}/$directory"
	    echo "Creating ${CHROOTDIR}/$directory"
	fi
done

# Creating necessary devices

[ -r ${CHROOTDIR}/dev/random ]     || mknod ${CHROOTDIR}/dev/random  c 1 8
[ -r ${CHROOTDIR}/dev/urandom ]    || mknod ${CHROOTDIR}/dev/urandom c 1 9
[ -r ${CHROOTDIR}/jail/dev/null ]  || mknod ${CHROOTDIR}/dev/null    c 1 3
[ -r ${CHROOTDIR}/jail/dev/zero ]  || mknod ${CHROOTDIR}/dev/zero    c 1 5
[ -r ${CHROOTDIR}/jail/dev/tty ]   || mknod ${CHROOTDIR}//dev/tty    c 5 0 && chmod 666 ${CHROOTDIR}/dev/tty
[ -r ${CHROOTDIR}/jail/dev/tty1 ]  || mknod ${CHROOTDIR}//dev/tty1   c 5 0 && chmod 666 ${CHROOTDIR}/dev/tty1

# If we only want to update the files in the jail
# skip the creation of the new account

if [ "$1" != "update" ]; 
    then

	# Modify /etc/security/chroot.conf to enable chroot-ing for users
	# user name must be removed by hand if function is not needed
	if ! grep ${CHROOT_USERNAME} /etc/security/chroot.conf > /dev/null 2>&1;
	    then
		echo "Modifying /etc/security/chroot.conf"
		echo -e "# generated by $(basename $0) $(date)\n${CHROOT_USERNAME}       ${CHROOTDIR}" >> /etc/security/chroot.conf
	fi

	# Modify /etc/pam.d/login to enable chroot-ing
	# must be removed by hand if account is deleted
	if ! grep pam_chroot.so /etc/pam.d/login > /dev/null 2>&1;
	    then
		echo "Modifying /etc/pam.d/login"
		echo -e "# \n# generated by $(basename $0) $(date)\nsession  required       pam_chroot.so" >> /etc/pam.d/login
	fi

	# Modify /etc/pam.d/sshd to enable chroot-ing
	# must be removed by hand if function is not needed
	if ! grep pam_chroot.so /etc/pam.d/sshd > /dev/null 2>&1;
	    then
		echo "Modifying /etc/pam.d/sshd"
		echo -e "# \n# generated by $(basename $0) $(date)\nsession  required       pam_chroot.so" >> /etc/pam.d/sshd
        fi
	
    # Modifiy /etc/ssh/sshd_config to enable chroot-ing
    # Only needed for openssh 3.3 or earlier
    #if ! grep "UsePrivilegeSeperation no" /etc/ssh/sshd_config > /dev/null 2>&1;
    #    then
    #	echo "Modifying /etc/ssh/sshd_config"
    #	echo "UsePrivilegeSeparation no" >> /etc/ssh/sshd_config
    #fi

    # Define passwd settings for simple referencing

    FULLNAME="*CHROOT ${CHROOT_USERNAME}*"
    PWFILE="/etc/passwd"	
    SHADOWFILE="/etc/shadow"
    GFILE="/etc/group"
    GID="100"
    GNAME="users"
    HOMEDIR="/home/$CHROOT_USERNAME"

    # check for another shell
    if ! [ -z "$3" ];
	then
	     SHELL=$3
	else
	    SHELL=/bin/bash
    fi
    

    # Exit if user already exists
    grep -q "^${CHROOT_USERNAME}:" /etc/passwd
    if [ "$?" -eq 0  ];
	then
	    echo -e "\n${CHROOT_USERNAME} already exists on the system\n"
	exit 1
    fi
    
    echo -e "Adding new user account to $(hostname)\n"

    useradd -M -d ${HOMEDIR} -s ${SHELL} -c "${FULLNAME}" ${CHROOT_USERNAME}
    sleep 1s

    mkdir ${CHROOTDIR}/${HOMEDIR}
    if [ $DISTRO = REDHAT ];
	then chown ${CHROOT_USERNAME}:${CHROOT_USERNAME} ${CHROOTDIR}/${HOMEDIR}
    else
	chown ${CHROOT_USERNAME}:${GNAME} ${CHROOTDIR}/${HOMEDIR}
    fi
    
    chmod 700 ${CHROOTDIR}/${HOMEDIR}
    
    # Enter password for new account
    
    echo ${CHROOT_USERNAME}:$2 | chpasswd
    
    # Create /usr/bin/groups command in the jail
    echo "#!/bin/bash" > ${CHROOTDIR}/usr/bin/groups
    echo "id -Gn" >> ${CHROOTDIR}/usr/bin/groups
    chmod 755 ${CHROOTDIR}/usr/bin/groups
    
    # Add users to the jail etc/passwd
    
    # grep the username which was given to us from /etc/passwd and add it
    # to /home/jail/${CHROOT_USER}/etc/passwd 
    
    echo -e "Adding User $CHROOT_USERNAME to jail\n"
    grep -e "^root" /etc/passwd > ${CHROOTDIR}/etc/passwd
    grep -e "^$CHROOT_USERNAME" /etc/passwd >> ${CHROOTDIR}/etc/passwd
    
    # Write the account's group from etc/group to /home/jail/${CHROOT_USERNAME}/etc/group
    
    grep -e "^root" /etc/group > ${CHROOTDIR}/etc/group
    grep -e "^users" /etc/group >> ${CHROOTDIR}/etc/group
    grep -e "^$CHROOT_USERNAME:" /etc/group >> ${CHROOTDIR}/etc/group
    
    # Write the user's line from /etc/shadow to /home/jail/etc/shadow
    # A RedHat thing
    
    grep -e "^$CHROOT_USERNAME:" /etc/shadow >> ${CHROOTDIR}/etc/shadow
    
# endif for =! update
fi

# Copy the apps and the related libs

echo -e "Copying necessary library-files to jail (may take some time)\n"

# The original code worked fine on 2.4 kernel systems. Kernel 2.6
# introduced an internal library called 'linux-gate.so.1'. This 
# 'phantom' library caused non-critical errors to display during the 
# copy since the file does not actually exist on the file system. 
# To fix re-direct output of ldd to a file, parse the file and get 
# library files that start with /

if [ -x /tmp/lddlist2 ];
    then
	mv /tmp/lddlist2 /tmp/lddlist2.bak
fi

for app in $APPS;
    do
	cp $app ${CHROOTDIR}/$app > /dev/null 2>&1
    # Get list of necessary libraries
	ldd $app >> /tmp/lddlist
    done

for libs in `cat /tmp/lddlist`;
    do
	frst_char="`echo $libs | cut -c1`"
	if [ "$frst_char" = "/" ];
	    then
		echo "$libs" >> /tmp/lddlist1
	fi
    done
    
# Get rid of duplicate entries
awk '{ if ($0 in stored_lines) 
    x=1 
    else 
	print 
	stored_lines[$0]=1 
	}' /tmp/lddlist1 > /tmp/lddlist2

# Copy needed libraries
for lib in `cat /tmp/lddlist2`;
    do
	mkdir -p ${CHROOTDIR}/`dirname $lib` > /dev/null 2>&1
	cp $lib ${CHROOTDIR}/$lib
    done

#
# Dump files created for the library listing
#

/bin/rm -f /tmp/lddlist
/bin/rm -f /tmp/lddlist1
/bin/rm -f /tmp/lddlist2
						     
# Necessary libraries that are not listed by ldd
if [ $DISTRO = SUSE ];
    then
	cp /lib/libnss_compat.so.2 /lib/libnss_files.so.2 ${CHROOTDIR}/lib/
    elif
	[ $DISTRO = REDHAT ];
    then
	cp /lib/libnss_compat.so.2 /lib/libnsl.so.1 /lib/libnss_files.so.2 /lib/ld-linux.so.2 /lib/ld-lsb.so.3 ${CHROOTDIR}/lib/
    else
	 echo -e "Something Broke, must exit\n"
    exit 1
fi

# Copy PAM stuff from /etc/pam.d/ to the jail
echo -e "Copying files from /etc/pam.d/ to jail\n"
cp /etc/pam.d/* ${CHROOTDIR}/etc/pam.d/
cp /etc/security/* ${CHROOTDIR}/etc/security/ > /dev/null 2>&1

# We only want the new user to show up in the jail version of this file
grep -B1 -e "^$CHROOT_USERNAME" /etc/security/chroot.conf > ${CHROOTDIR}/etc/security/chroot.conf
chmod 644 ${CHROOTDIR}/etc/security/chroot.conf

# Also grab the PAM-modules
echo -e "Copying PAM-Modules to jail\n"
cp -r /lib/security ${CHROOTDIR}/lib/

# a few more files we need to create
# this should stop the syslogin errors in the messages file
touch ${CHROOTDIR}/var/log/wtmp
touch ${CHROOTDIR}/var/log/lastlog
touch ${CHROOTDIR}/var/run/utmp

echo -e "All Done!!!!!\n"

exit

