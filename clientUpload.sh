#!/bin/bash

SERVER="http://example.tld"
FILE="$1"
if [ -z "$FILE" ];then
    exit -1
fi

EXPIRES=`zenity --list \
    --title="Choose Expiration" \
    --column="Expiration" \
    10m \
    30m \
    1h \
    4h \
    1d \
    30d`

IMPATH=`curl -F "image=@$FILE" -F "expires=$EXPIRES" "$SERVER/upload" \
    |  grep -Poh '(?<="path":")[^"]+'`
if [[ -z "$IMPATH" ]]; then
    notify-send "Uploading $FILE failed"
    exit -1
fi

echo "$SERVER/$IMPATH" | xclip -i -selection clipboard
notify-send "Uploaded $FILE to $SERVER/$IMPATH"
