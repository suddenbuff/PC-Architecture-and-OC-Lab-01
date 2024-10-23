#!/bin/bash

targetFolder="$1"
threshold=$2
number=$3

if [ -z "$3" ]; then
    echo "ERROR: expected 3 arguments, got less"
    exit 1
elif [ ! -d "$targetFolder" ]; then
    echo "ERROR: $targetFolder does not exist."
    exit 1
elif ! expr "$threshold" + 0 >/dev/null 2>&1 || [ $threshold -lt 0 ]; then
    echo "ERROR: entered percentage of threshold is not a number or it must be at least 0"
    exit 1
elif ! expr "$number" + 0 >/dev/null 2>&1 || [ $number -lt 1 ] ; then
    echo "ERROR: entered number of archived files is not a number or it must be at least 1"
    exit 1
fi

usedSpaceInPercents=$(df filesystem --output=pcent | tail -n 1 | tr -d ' %')

if [ $usedSpaceInPercents -gt $threshold ]; then
    
    echo "Archiving has started"
    archiveName="backup_$(date +"%Y-%m-%d_%H-%M-%S")"
    
    if [ ! -d ~/backup ]; then
        mkdir backup
    fi
    
    tar cf ~/backup/$archiveName.tar --files-from=/dev/null

    for file in $(ls -ltr "$targetFolder" | grep '^-' | awk '{print $9}'); do
        number=$((number-1))
        tar rf ~/backup/$archiveName.tar $targetFolder/$file
        sudo rm $targetFolder/$file

        if [ $number -eq 0 ]; then
            break
        fi
    done
    
    gzip -c ~/backup/$archiveName.tar > ~/backup/$archiveName.gz
    rm ~/backup/$archiveName.tar
    echo "Archiving is complete"
else
    echo "Used $usedSpaceInPercents %. It is less than $threshold %, archiving is not required"
fi
