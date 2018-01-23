#!/bin/bash
#
#

START=$( date +%s )

TOOL="$1"
BACK=$( pwd )

	IGNORE=$( git svn show-ignore 2>/dev/null )
	if [[ $IGNORE != "" ]]; then
		echo $IGNORE > .gitignore
#		git add .gitignore
#		git commit -m "converting ignores for $branch"
	fi



FINISH=$( date +%s )

TIME=$( expr $FINISH - $START )

echo "Finished in $TIME seconds"
