# feralhosting-freenas_lftp
Guide to Sync Feral Server Directory with Freenas Jail with Open-vpn with lftp (sftp)

### Automated LFTP Sync from SeedBox to Home

This tutorial will explain how to use an automated LFTP script that runs every few minutes (or of your choosing) matching a remote directory with your home.  This script only works one way, so if you remove the file on your server, it will not be removed from your home directory.  It will also work with Windows, Mac, and Linux.

I prefer LFTP because, not only is it a fully automated daemon, it also maximizes my home pipeline. LFTP supports parallel downloads of the same file while also downloading others as well. Only one instance of this script will run, if it is currently transferring, it creates a lock and will not run again until the current operation has completed.

### Freenas (freebsd) 

#### Initial Setup

1. Create a new jail using the web gui (see here if unsure https://doc.freenas.org/9.10/jails.html )
2. Add storage to the jail using the web gui (Jail>Storage>Add Storage)
3. Open an ssh connection to your freenas box as root (eg. ssh root@freenas.local)
4. Type jls and record jail number 
5. Type the following: (anything in brackets replace with your specific configuration)
  jexec (4) tcsh
  pkg clear
  pkg update
  pkg upgrade
  pkg install nano
  pkg install bash
  pkg install lftp
6. Now we need to setup a user and group in the jail so that our files have the permissions we want
  pw groupadd (groupname)
  adduser (username)
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
wget -qO syncdownloads.sh https://github.com/CJBlake/feralhosting-freenas_lftp/blob/master/syncdownloads.sh
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
          mkdir ~/scripts
          cd ~/scripts
          wget -qO runsync.sh https://github.com/CJBlake/feralhosting-freenas_lftp/blob/master/runsync.sh
    4. Open the freenas webgui and go to Task>Cron Jobs>Add Cron Job, These are the values you need to configure replace what is in brackets with your relevant information the defaults are fin for the rest. 
        User : root
        Command : jexec (jailname not number as this can change) bash su mediaplayer ~/scripts/syncdownloads.sh
        Description : (Download Files From Feral Seedbox)
        Minute (every n minute) : 15
        
    

I must give credit to [LordHades](http://www.torrent-invites.com/seedbox-tutorials/132965-tutorial-auto-sync-seedbox-home-linux-mac-machine-lftp-shell-script.html) who created this amazing script.



