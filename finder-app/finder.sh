#!/bin/sh
#
# Finder app.


# Start checking for the correct amount of arguments
# The script should be called with 2 arguments
# $1 is the path to a directory `filesdir`
# $2 is a string `searchstr`
#
# Output is "The number of files are X and the number of matching lines are Y"

if [ $# -ne 2 ]; then
	echo "Invalid number of parameters given."
	exit 1
fi
if [ ! -d "$1" ]; then
	echo "$1 is not a directory"
	exit 1
fi

# Add a named variable for the search directory and search string
filesdir=$1
searchstr=$2

echo "Searching for: $searchstr"

# count the files contained in the directory
# named as X in the example
X=$( find "$filesdir" -type f | wc -l)
Y=$( grep -r "$searchstr" "$filesdir" | wc -l)



echo "The number of files are ${X} and the number of matching lines are ${Y}"
