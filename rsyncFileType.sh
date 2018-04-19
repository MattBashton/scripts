#!/bin/bash -eu
# Matthew Bashton 2018
# Uses rsync to copy over a specific file type from a directory tree to a remote destination
# Uses GNU parallel to run multiple copy operations at once
tput bold
[ $# -ne 4 ] && { echo -en "\nRsync all files in a tree of specific type in parallel\n------------------------------------------------------\n\n - Matthew Bashton 2018\n - This script copies all files from dest to source using rsync and GNU parallel\n\n Error Nothing to do, usage:\n rsynFileType.sh <source dir(will be recursed)> <destination: user@host:path/> <file type to copy (e.g. *.bam)> <number parallel threads to copy multiple files on> \n - Note: requires public key on remote host to work\n\n" ; exit 1; }
set -o pipefail
tput sgr0

tput bold
echo -en "Rsync all files in a tree of specific type in parallel \n------------------------------------------------------\n\n - Matthew Bashton 2018\n\n"
tput sgr0
echo -n "Client: "
hostname
echo -n "Time: "
date

# Get command-line args
SOURCE=$1
DEST=$2
TYPE=$3
CPU=$4

# Rsync flags to use
FLAGS="-vlt -e ssh"

# Job_list_file
JL_FILE="rsync_jobs.txt"

# Variables
echo " "
echo " * Source path is: $SOURCE"
echo " * Destination directory is: $DEST"
echo " * File type to copy from recursed source tree: $TYPE"
echo " * Number of simluatious transfers: $CPU"
echo " * Rsync flags: $FLAGS"
echo " * Rsync jobs written to: $JL_FILE"
echo " "

# Get list of source files with find
tput bold
echo -ne "Finding all $TYPE files in $SOURCE:\n"
tput sgr0

# Don't split on white space!
IFS=$'\n'

# Get out list
FILE_LIST=( $(find "$SOURCE" -name "$TYPE" -type f | sed -e 's/ /\\ /g') )

for FILE in ${FILE_LIST[@]}
do
    echo "$FILE"
done

NO_FILES=${#FILE_LIST[@]}

tput bold
echo -ne "\nFound $NO_FILES to copy\n"
tput sgr0

# Remove existing jobs file if exists
if [ -e $JL_FILE ]
then
    rm $JL_FILE
fi

COUNT=1

# Generate job list
for FILE in ${FILE_LIST[@]}
do
    #echo -ne "Makeing job $COUNT of $NO_FILES\n"
    echo "rsync $FLAGS $FILE $DEST" >> $JL_FILE
    ((COUNT++))
done

tput bold
echo -ne "\n$NO_FILES jobs written to $JL_FILE\n"
tput sgr0

# Run these
tput bold
echo -ne "Setting of $CPU transfer(s) to $SOURCE for $NO_FILES files...\n"
tput sgr0

LOG_F="transfer_log.txt"
parallel --progress --jobs $CPU --joblog $LOG_F < $JL_FILE
tput bold
echo -ne "\nDone! - Run logged to $LOG_F\n"
tput sgr0
