#!/bin/bash

###### Get User unput for varibles and check with user they are correct
while true; do
    echo "Enter desired username for lftp service"
	read uname
	echo "Enter desired UID of user"
	read uid
	echo "Enter Desired groupname for lftp service"
	read grpname
	echo "Enter Username to Seedbox Server for SFTP"
	read flogin
	echo "Enter Password to Seedbox Server for SFTP"
	read fpass
	echo "Enter homename to Seedbox Server eg. monkey.feralhosting.com "
	read fhost
	echo "Enter the remote directory path you want to copy"
	echo "eg. ~/folder/you/want/to/copy"
	read fremote_dir
	echo "Enter the local path you want to copy to"
	echo "eg. /folder/you/mounted/to/jail"
	read flocal_dir

	echo "Are these values correct\?"
	echo "LFTP USER = $uname"
	echo "LFTP USER UID = $uid"
	echo "GROUP NAME = $grpname"
	echo "Seedbox Login = $flogin"
	echo "Seedbox Password = $fpass"
	echo "Seedbox Hostname = $fhost"
	echo "Remote Directory = $fremote_dir"
	echo "Local Directory = $flocal_dir"
	read -p "Are these values correct?" yn
	case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

pkg clean -y
pkg update -f
pkg upgrade -y
pkg install -y nano
pkg install -y bash
pkg install -y lftp
pkg install -y wget
pw groupadd "$grpname"
pw useradd -m -s tcsh -u "$uid" -g "$grpname" -n "$uname"
su "$uname" -c "mkdir ~/scripts"
su "$uname" -c "mkdir ~/temp"
su "$uname" -c "cat > ~/scripts/syncdownloads.sh << 'ENDMASTER'
$(
###### The parameter substitution is on here
cat <<INNERMASTER
#!/bin/bash
login="$flogin"
pass="$fpass"
host="$fhost"
remote_dir="$fremote_dir"
local_dir="$flocal_dir"
temp_dir="~/temp"

INNERMASTER

###### No parameter substitution
cat <<'INNERMASTER'
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
    mv  -v "$temp_dir/*" "$local_dir"
    trap - SIGINT SIGTERM
    exit
fi

INNERMASTER
)
ENDMASTER"
su "$uname" -c "chmod 700 ~/scripts/syncdownloads.sh" # Make the script executable
mkdir ~/scripts
cat >~/scripts/runsync.sh <<EOF2
#!/bin/bash
su  "$uname" -c "bash ~/scripts/syncdownloads.sh";
EOF2
chmod 700 ~/scripts/runsync.sh

exit 0
