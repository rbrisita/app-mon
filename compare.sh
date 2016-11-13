#!/usr/bin/env bash

# Find today's and yesterday's date.
# Read targets from file.
# Create path to files.
# Compare files with diff_ratio.
# @author Robert Brisita <robert.brisita@gmail.com> rbrisita

# DATE='20140509'

if [ -z "$1" ]
then
	echo "Usage: $0 <JSON file>"
	echo 'JSON Format: {"target":"http://example.com"}'
	exit 1
fi

readonly DATE_FMT=%Y/%m/%d/

# Find current date and previous day depending on OS.
if [[ "$OSTYPE" == "darwin"* || "$OSTYPE" == "freebsd"* ]]
then
	NOW=$(date -uj +"$DATE_FMT")
	PREV=$(date -ujv -1d +"$DATE_FMT")
elif [[ "$OSTYPE" == "linux-gnu" ]]
then
	# -d Display date.
	NOW=$(date -u +"$DATE_FMT")
	PREV=$(date -ud "1 day ago" +"$DATE_FMT")
else
	echo "$OSTYPE date utility not supported or tested."
	echo "Please use Mac OS X, FreeBSD, or Linux."
	exit 2
fi

readonly EXT='.png'
readonly QUOTES='"'
readonly SUB_STR=':/'
readonly EMPTY=''
readonly COMMA=','
readonly L_SQR_BRACKET='['
readonly R_SQR_BRACKET=']'
readonly L_PARENTHESES='('
readonly R_PARENTHESES=')'
readonly SPACE=' '

# Parse JSON file for targets.
jq -c '.[] | [.target, .diffRatio]' "$1" | while IFS= read -r line
do
	# Convert URL to file path.
	build=${line/$QUOTES/$EMPTY}
	build=${build/$QUOTES/$EMPTY}
	build=${build/$SUB_STR/$EMPTY}

	# Convert to BASH array.
	build=${build/$L_SQR_BRACKET/$L_PARENTHESES}
	build=${build/$R_SQR_BRACKET/$R_PARENTHESES}
	build=${build/$COMMA/$SPACE}

	declare -a arr=$build

	# Set parameters.
	fileName=${arr[0]}
	ratio=${arr[1]}

	# Create file paths.
	base=$PREV$fileName$EXT
	cur=$NOW$fileName$EXT

	echo "Comparing"
	echo "'$base'"
	echo "and"
	echo "'$cur'"
	echo "with $ratio% difference threshold."

	# Are files readable?
	if [ -r "$base" ] && [ -r "$cur" ]
	then
		JSON=$(./imgdiff.sh "$base" "$cur" "$ratio")
		status=$?

		# Did comparison surpass threshold?
		if [ $status -ne 0 ]
		then
			echo "ERROR LOG: $line $JSON"
			echo "TODO: LARAVEL TASK Store for alerting later"
		fi

		#ALERT=$(echo $JSON | jq '.diff')
		#echo "Project $line : Alert: $ALERT"
	else
		echo "'$BASE' or '$CUR' not found!"
		echo "TODO: LARAVEL TASK Store for alerting later"
	fi
done
