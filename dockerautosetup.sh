#!/bin/bash

###### GET Enviroment varibles from docker
uname="${LFTP_USER}"
uid="${LFTP_UID}"
grpname="${LFTP_GROUP}"
gid="${LFTP_GID}"
flogin="${FERAL_USERNAME}"
fpass="${FERAL_PASSWORD}"
fhost="${FERAL_HOST}"
fremote_movie_dir="${REMOTE_MOVIE_DIR}"
fremote_tv_dir="${REMOTE_TV_DIR}"
local_movie_dir="${LOCAL_MOVIE_DIR}"
local_tv_dir="${LOCAL_TV_DIR}"
temp_movie_dir="${TEMP_MOVIE_DIR}"
temp_tv_dir="${TEMP_TV_DIR}"
log_dir="${LFTP_LOG_DIR}"

groupadd -g "$gid" "$grpname"
useradd -u "$uid" -g "$grpname" -d "/config/$uname" "$uname"
echo "${LFTP_USER}":"${USER_PASSWORD}" | chpasswd
su "$uname" -c "mkdir /config/scripts"
su "$uname" -c "cat > /config/scripts/sync_movie_downloads.sh << 'ENDMASTER'
$(
###### The parameter substitution is on here
cat <<INNERMASTER
#!/bin/bash
login="$flogin"
pass="$fpass"
host="$fhost"
remote_dir="$fremote_movie_dir"
local_dir="$local_movie_dir"
temp_dir="$temp_movie_dir"
upload_rate="0"
download_rate="0"
INNERMASTER
###### No parameter substitution
cat <<'INNERMASTER'
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
        upload_rate="100000"
        download_rate="2000000"
        echo "limit on"
    else
        upload_rate="0"
        download_rate="0"
        echo "limit off"
    fi
    lftp -p 22 -u "$login","$pass" sftp://"$host" << EOF
    set sftp:auto-confirm yes
    set net:limit-rate "$upload_rate":"$download_rate"
    set mirror:use-pget-n 20
    mirror -c -v -P2 --loop --Remove-source-dirs "$remote_dir" "$temp_dir"
    quit
EOF
    cp -val "$temp_dir"/* "$local_dir"
    rm -rf "$temp_dir"/*
    chmod -R 775 "$local_dir"
    rm -f "$lock_file"
    trap - SIGINT SIGTERM
    exit
fi
INNERMASTER
)
ENDMASTER"
su "$uname" -c "chmod 770 /config/scripts/sync_movie_downloads.sh" # Make the script executable
su "$uname" -c "cat > /config/scripts/sync_tv_downloads.sh << 'ENDMASTER'
$(
###### The parameter substitution is on here
cat <<INNERMASTER
#!/bin/bash
login="$flogin"
pass="$fpass"
host="$fhost"
remote_dir="$fremote_tv_dir"
local_dir="$local_tv_dir"
temp_dir="$temp_tv_dir"
upload_rate="0"
download_rate="0"
INNERMASTER
###### No parameter substitution
cat <<'INNERMASTER'
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
        upload_rate="100000"
        download_rate="2000000"
        echo "limit on"
    else
        upload_rate="0"
        download_rate="0"
        echo "limit off"
    fi
    lftp -p 22 -u "$login","$pass" sftp://"$host" << EOF
    set sftp:auto-confirm yes
    set net:limit-rate "$upload_rate":"$download_rate"
    set mirror:use-pget-n 20
    mirror -c -v -P2 --loop --Remove-source-dirs "$remote_dir" "$temp_dir"
    quit
EOF
    cp -val "$temp_dir"/* "$local_dir"
    rm -rf "$temp_dir"/*
    chmod -R 775 "$local_dir"
    rm -f "$lock_file"
    trap - SIGINT SIGTERM
    exit
fi
INNERMASTER
)
ENDMASTER"
su "$uname" -c "chmod 770 /config/scripts/sync_tv_downloads.sh" # Make the script executable

touch "$log_dir/setup.log"
echo "time: $(date). - setup successful" >> "$log_dir/setup.log"

exit 0
