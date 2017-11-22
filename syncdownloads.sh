'#!/bin/bash
login="username"
pass="password"
host="server.feralhosting.com"
remote_dir='~/folder/you/want/to/copy'
local_dir="/folder/you/mounted/to/jail"
temp_dir='/temp'
upload_rate="0"
download_rate="0"
H=$(date +%H)


base_name="$(basename "$0")"
lock_file="/tmp/$base_name.lock"
trap "rm -f $lock_file; exit 0" SIGINT SIGTERM
if [ -e "$lock_file" ]
then
    echo "$base_name is running already."
    exit
else
    touch "$lock_file"
    if (( 9 <= 10#$H && 10#$H < 24 )); then
        upload_rate="125000"
        download_rate="5000000"
        echo "limit on"
    else
        upload_rate="0"
        download_rate="0"
        echo "limit off"
    fi
    lftp -p 22 -u "$login","$pass" sftp://"$host" << EOF
    set sftp:auto-confirm yes
    set net:limit-rate "$upload_rate":"$download_rate"
    set mirror:use-pget-n 50
    mirror -c -v -P3 --loop --Remove-source-dirs "$remote_dir" "$temp_dir"
    quit
EOF
    mv  -v /temp/* "$local_dir"
    rm -f "$lock_file"
    trap - SIGINT SIGTERM
    exit

fi
