#!/usr/bin/env bash

# Application Monitor Main File.
# @author Robert Brisita <robert.brisita@gmail.com>

# DATE='20140616'

# TODO: Check if all required software is installed

if [ -z "$1" ]
then
	echo "Usage: $0 <JSON String | JSON file containing URLs>"
	echo 'JSON file format: {"target":"URL" [, "delay":number]}'
	exit 1
fi

# Check 3rd Party Statistics
./3rdPartyStats.sh
isDown=$?
if [ $isDown -gt 0 ]
then
	echo "$isDown targets down" # A server or site was found to be down
fi

# No server or site was found to be down

# Remove files older than 7 days.
./removeFiles.sh 7

# Create screen captures of targets found in app-mon.json.
phantomjs capture.js "$1" # app-mon.json

# Compare day old images with newly created images.
./compare.sh "$1" # app-mon.json

# Alert of any images that break the threshold.
# TODO: Store into DB
