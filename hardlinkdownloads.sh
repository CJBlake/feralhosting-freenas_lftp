#!/bin/sh
name=$1
base_path=$2
synctvshows_path="/media/sdab1/username/Downloads/completed/"
base_name="$(basename "$0")"
lock_file="/media/sdab1/username/tmp/$base_name.lock"
trap "rm -f $lock_file exit 0" SIGINT SIGTERM

while [ -e "$lock_file" ]
do
    echo "Sync in progress waiting 200 seconds $(date) $line" >> /media/sdab1/username/logs/hardlinkdownloads.log
    sleep 200
done
touch "$lock_file"
cp -val "$2" "$synctvshows_path"
echo "Created a hardlink of $name in LFTP sync folder" >> /media/sdab1/username/logs/hardlinkdownloads.log
echo "$2" >> /media/sdab1/username/logs/hardlinkdownloads.log

bash "/media/sdab1/username/Scripts/syncdownload.sh"
rm -f "$lock_file"
trap - SIGINT SIGTERM

exit 0
