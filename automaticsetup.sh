#!/bin/bash
jail="jailname" 
uname="username"
uid="uid of freenas share user"
grpname="group name"
flogin="username for feral ftp"
fpass="password for feral ftp"
fhost="server.feralhosting.com"
fremote_dir='~/folder/you/want/to/copy'
flocal_dir="/folder/you/mounted/to/jail"

jexec "$jail" tcsh
pkg clear -y
pkg update -y
pkg upgrade -y
pkg install nano -y
pkg install bash -y
pkg install lftp -y
pkg intall wget -y
pw groupadd "$grpname"
adduser 
""$uname"
"$uname"
"$uid"
"$grpname"


tcsh


no
no
yes
no"
su "$uname"
mkdir ~/scripts
cd ~/scripts
cat > syncdownloads.sh <<EOF1
#!/bin/bash
login="$flogin"
pass="$fpass"
host="$fhost"
remote_dir="$fremote_dir"
local_dir="$flocal_dir"

base_name="$(basename "$0")"
lock_file="/tmp/$base_name.lock"
trap "rm -f $lock_file exit 0" SIGINT SIGTERM
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
EOF1
chmod 700 syncdownloads.sh # Make the script executable
exit
mkdir ~/scripts
cd ~/scripts
cat >runsync.sh <<EOF2
#!/bin/bash
su  "#uname" -c "bash ~/scripts/syncdownloads.sh";
EOF2
chmod 700 runsync.sh
