#!/usr/bin/env bash

# Compare given images.
# Scale both images down to a percentage.
# Compare for absolute error with a fuzz factor.
# @author Robert Brisita <robert.brisita@gmail.com>

# DATE='20140509'

PERCENT="25"
FUZZ="10"

[ "$#" != "3" ] && echo "Syntax: $0 IMAGE1 IMAGE2 RATIO" >&2 && exit 2

IMG1="$1"
IMG2="$2"
RATIO="$3"

# Check for valid value.
if [ "$RATIO" == "null" ]
then
	RATIO=10
fi

# Find file size in bytes depending on OS.
if [[ "$OSTYPE" == "darwin"* || "$OSTYPE" == "freebsd"* ]]
then
	SIZE1=$(stat -f '%z' "$IMG1")
	SIZE2=$(stat -f '%z' "$IMG2")
elif [[ "$OSTYPE" == "linux-gnu" ]]
then
	SIZE1=$(stat -c '%s' "$IMG1")
	SIZE2=$(stat -c '%s' "$IMG2")
else
	echo "$OSTYPE stat utility not supported or tested."
	echo "Please use Mac OS X, FreeBSD, or Linux."
	exit 2
fi

# Find larger image.
if [ "$SIZE1" -lt "$SIZE2" ]
then
	BIG="$IMG2"
	SMALL="$IMG1"
else
	BIG="$IMG1"
	SMALL="$IMG2"
fi

#echo "1) Scaling both images to $PERCENT% of smaller image"
#echo "2) Counting different pixels (color distance > $FUZZ%)"

SIZE=$(identify -format '%wx%h' "$SMALL")

W=$(echo "$SIZE" | cut -dx -f1)
H=$(echo "$SIZE" | cut -dx -f2)

W=$(( ($W * $PERCENT) / 100 ))
H=$(( ($H * $PERCENT) / 100 ))

# Convert and compare images.
DIFF=$( convert "$SMALL" "$BIG" -resize "$W"x"$H"\! MIFF:- | compare -metric AE -fuzz "$FUZZ%" - null: 2>&1 )
[ "$?" != "0" ] && echo "$DIFF" >&2

# Get difference ratio and create JSON output.
DIFF_RATIO=$(awk "BEGIN {printf \"%.3f\n\", ($DIFF / ($W*$H))*100 }")
JSON="{\"ratio\":$DIFF_RATIO, \"diff\":$DIFF}"

#echo "pixel difference: $DIFF_RATIO%"
echo "$JSON"

function float_cond()
{
    local cond=0
    if [[ $# -gt 0 ]]; then
        cond=$(echo "$*" | bc -q 2>/dev/null)
        if [[ -z "$cond" ]]; then cond=0; fi
        if [[ "$cond" != 0  &&  "$cond" != 1 ]]; then cond=0; fi
    fi
    local stat=$((cond == 0))
    return $stat
}

# Test against threshold.
if float_cond "$DIFF_RATIO < $RATIO"
then
	exit 0 	# echo "OK"
else
	exit 1	# echo "NOK"
fi
