# feralhosting-freenas_lftp
Guide to Sync Feral Server Directory with Freenas Jail with Open-vpn with lftp (sftp)

### Automated LFTP Sync from SeedBox to Home

This tutorial will explain how to use an automated LFTP script that runs every few minutes (or of your choosing) matching a remote directory with your home.  This script only works one way, so if you remove the file on your server, it will not be removed from your home directory.  It will also work with Windows, Mac, and Linux.

I prefer LFTP because, not only is it a fully automated daemon, it also maximizes my home pipeline. LFTP supports parallel downloads of the same file while also downloading others as well. Only one instance of this script will run, if it is currently transferring, it creates a lock and will not run again until the current operation has completed.

### Freenas (freebsd) 

#### Automatic Setup ####
1. Create a new jail using the web gui (see here if unsure https://doc.freenas.org/9.10/jails.html )
2. Add storage to the jail using the web gui (Jail>Storage>Add Storage)
3. Open an ssh connection to your freenas box as root (eg. ssh root@freenas.local)
4. Type jls and record jail number 
5. Type the following: (anything in brackets replace with your specific configuration)
  ~~~
  jexec (4) tcsh
  pkg install -y bash
  pkg intall -y wget
  wget -q /automaticsetup.sh https://raw.githubusercontent.com/CJBlake/feralhosting-freenas_lftp/master/automaticsetup.sh
  chmod 770 /automaticsetup.sh
  bash /automaticsetup.sh
  ~~~
 6. Now you can skip to "Setup Cron Job In Freenas " step 6

#### Manual Setup

1. Create a new jail using the web gui (see here if unsure https://doc.freenas.org/9.10/jails.html )
2. Add storage to the jail using the web gui (Jail>Storage>Add Storage)
3. Open an ssh connection to your freenas box as root (eg. ssh root@freenas.local)
4. Type jls and record jail number 
5. Type the following: (anything in brackets replace with your specific configuration)
  ~~~
  jexec (4) tcsh
  pkg clear
  pkg update
  pkg upgrade
  pkg install nano
  pkg install bash
  pkg install lftp
  pkg intall wget
  ~~~
6. Now we need to setup a user and group in the jail so that our files have the permissions we want
  ~~~
  pw groupadd (groupname)
  adduser (username)
  ~~~
7. Once you type in the previous command a set of questions will come up specify the uid that matches the uid of the owner of the share on your freenas box and the group you just created, the default setting are fine for the rest

#### Download and configure the script

Here is the script to manually copy and paste:

~~~
#!/bin/bash
login="username"
pass="password"
host="server.feralhosting.com"
remote_dir='~/folder/you/want/to/copy'
local_dir="/folder/you/mounted/to/jail"

base_name="$(basename "$0")"
lock_file="/tmp/$base_name.lock"
trap "rm -f $lock_file; exit 0" SIGINT SIGTERM
if [ -e "$lock_file" ]
then
    echo "$base_name is running already."
    exit
else
    touch "$lock_file"
    lftp -p 22 -u "$login","$pass" sftp://"$host" << EOF
    set sftp:auto-confirm yes
    set mirror:use-pget-n 5
    mirror -c -P5 "$remote_dir" "$local_dir"
    quit
EOF
    rm -f "$lock_file"
    trap - SIGINT SIGTERM
    exit
fi
~~~

Run this to download the script in your jail and confiure it 

~~~
su (username) 
mkdir ~/scripts
cd ~/scripts
wget -q https://raw.githubusercontent.com/CJBlake/feralhosting-freenas_lftp/master/syncdownloads.sh
nano syncdownloads.sh
~~~

In the script these are the variables you will need to customise to meet your requirements.

~~~
#!/bin/bash
login="username"
pass="password"
host="server.feralhosting.com"
remote_dir='~/folder/you/want/to/copy'
local_dir="$HOME/lftp/"
~~~

Make the script executable and only readable to your jail user:

~~~
chmod 700 synctorrents.sh
~~~

The important parameters for `lftp` are:

~~~
set mirror:use-pget-n 5
~~~

This makes lftp try to split up files in 5 pieces for parallel downloading. Likewise,

~~~
-P5
~~~

 
Means it will download at most 5 files in parallel (for a total 25 connections). Those 2 combined work wonders. In my case, I always end up downloading the files at the limit of my connection, but feel free to play with them and find what works best for you.

~~~
-c
~~~
Just tells it to try and resume an interrupted download if it' s the case.

#### Check that the script is now working 

~~~
bash synctorrents.sh
~~~

#### Setup Cron Job In Freenas 
1. Now we need to make a script to allow the root user to run the command as (username) in the jail so that our new files have the correct permissions
2. Type: exit (to return to root user in the jail)
3. Run these commands:
  ~~~
  mkdir ~/scripts
  cd ~/scripts
  wget -q https://raw.githubusercontent.com/CJBlake/feralhosting-freenas_lftp/master/runsync.sh
  chmod 700 runsync.sh
  ~~~
4. Open the script and chage username to your respective username
  ~~~
  nano runsync.sh
  ~~~
6. Open the freenas webgui and go to Task>Cron Jobs>Add Cron Job, These are the values you need to 
configure replace what is in   brackets with your relevant information the defaults are fin for the rest. 
  ~~~
  User : root
  Command : jexec (jailname not number as this can change) bash ~/scripts/runsync.sh
  Description : (Download Files From Feral Seedbox)
  Minute (every n minute) : 15
  ~~~
  
  ****(Additional Tip: If you use sonarr or a similar program to manage your media make sure you use Remote Path Mappings so that sonarr can correctly immport your files)
    

I must give credit to [LordHades repo](http://www.torrent-invites.com/seedbox-tutorials/132965-tutorial-auto-sync-seedbox-home-linux-mac-machine-lftp-shell-script.html) who made the basis of this script
And also the [feralfilehosting repo](https://github.com/feralhosting/feralfilehosting/blob/master/Feral%20Wiki/SFTP%20and%20FTP/LFTP%20-%20Automated%20sync%20from%20seedbox%20to%20home/readme.md) whose instructions were used to configure this script and intructions for a feral server seedbox, however that should work for any server/seedbox that supports SFTP and LFTP.



