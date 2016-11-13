#!/usr/bin/env bash

# Request statistics from a 3rd party monitoring service.
# Parse data to find out specific statistics.
# @author Robert Brisita <robert.brisita@gmail.com>

# DATE='20140613'

# http://api.uptimerobot.com/getMonitors?apiKey={API_KEY}&format=json&noJsonCallback=1
readonly API_KEY=''
if [ -z "$API_KEY" ]
then
	echo "Please set API_KEY from https://www.uptimerobot.com"
	exit -1
fi

readonly COMMA=','
readonly L_SQR_BRACKET='['
readonly R_SQR_BRACKET=']'
readonly L_PARENTHESES='('
readonly R_PARENTHESES=')'
readonly SPACE=' '

# Uptime Robot
# Types
readonly HTTP=1
readonly PING=3
readonly TYPES=('0 Not Used' 'HTTP' '2 Not Used' 'PING')

# Condition
readonly UP=2

readonly TEMP_FILE=$(mktemp "/tmp/$0.json.XXXXXXXXXX")

isDown=0

curl -s -H "User-Agent: Application Monitor" \
"http://api.uptimerobot.com/getMonitors?apiKey=$API_KEY&format=json&noJsonCallback=1" > "$TEMP_FILE" 2>&1

while IFS= read -r line
do
	# Convert to BASH array.
	build=${line/$L_SQR_BRACKET/$L_PARENTHESES}
	build=${build/$R_SQR_BRACKET/$R_PARENTHESES}
	build=${build/$COMMA/$SPACE}
	build=${build/$COMMA/$SPACE}
	build=${build/$COMMA/$SPACE}
	build=${build/$COMMA/$SPACE}

	declare -a arr=$build

	# Set parameters.
	name=${arr[0]}
	url=${arr[1]}
	checkType=${arr[2]}
	status=${arr[3]}

	if [ "$status" -gt "$UP" ]
	then
		echo "ERROR LOG: ${TYPES[$checkType]} $name: $url is down"
		echo "TODO: LARAVEL TASK Store for alerting later"
		isDown=$((isDown + 1))
	fi
done <<EOT
$(jq -c '.monitors.monitor[] | [.friendlyname, .url, .type, .status]' "$TEMP_FILE")
EOT

exit $isDown
