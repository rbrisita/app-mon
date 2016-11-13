#!/usr/bin/env bash

# Remove files and folders after given days.
# @author Robert Brisita <robert.brisita@gmail.com>

# DATE='20140425'

if [ -z "$1" ]
then
	echo "Usage: $0 <number of days old>"
	exit 1
fi

# Find and remove files of type that are given days old.
# find . -iname '*.'$1 -type f -mtime +$2 -exec rm {} \; # Deprecated.

# Create folder path to old folders and delete.
# -u UTC.
if [[ "$OSTYPE" == "darwin"* || "$OSTYPE" == "freebsd"* ]]
then
	# -j Don't set time.
	# -v Date adjust.
	OLD=$(date -ujv -"$1"d +%Y/%m/%d)
	MONTH_LAST_DAY=$(date -ujv +1m -v 1d -v -1d +%d)
elif [[ "$OSTYPE" == "linux-gnu" ]]
then
	# -d Display date.
	OLD=$(date -ud "$1 day ago" +%Y/%m/%d)
	MONTH_LAST_DAY=$(date -ud "+1 month -$(date +%d) days" +%d)
else
	echo "$OSTYPE date utility not supported or tested."
	echo "Please use Mac OS X, FreeBSD, or Linux."
	exit 2
fi

# If $OLD was '' then it would be "rm -rf /" o_O.
if [ -n "$OLD" ]
then
	echo "Removing files $1 days old on $OLD."
	rm -rf "$OLD/" # TODO: There is a safer way to do this.
fi

# Split date into array to check if month folder and year folder have to be deleted.
IFS="/"
read -ra arr <<< "$OLD"
unset IFS

YEAR=${arr[0]}
MONTH=${arr[1]}
DAY=${arr[2]}

if [ "$MONTH" == 12 ]
then
	# Remove year folder
	echo rm -rf "$YEAR"
elif [ "$MONTH_LAST_DAY" == "$DAY" ]
then
	# Remove month folder
	echo rm -rf "$YEAR/$MONTH"
fi
