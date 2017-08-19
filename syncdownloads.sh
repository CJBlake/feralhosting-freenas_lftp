#!/bin/bash
login="username"
pass="password"
host="server.feralhosting.com"
remote_dir='~/folder/you/want/to/copy'
local_dir="/folder/you/mounted/to/jail"
temp_dir='~/temp'

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
    mirror -c -P5 "$remote_dir" "$temp_dir"
    quit
EOF
    rm -f "$lock_file"
    trap - SIGINT SIGTERM
    mv  -v "$temp_dir/*" "$local_dir"
    exit
fi
