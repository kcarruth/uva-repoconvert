#!/bin/bash
#
# fix-up placeholder empty commits

BASEDIR="/home/vagrant/repoconv"
WORKDIR="$BASEDIR/work"
TOOLDIR="$WORKDIR/tools"

for tool in $( ls $TOOLDIR ); do
	cd $TOOLDIR/$tool

	for branch in $( git branch | sed "s/^..//" ); do
		git checkout $branch 2>/dev/null

		placeholders=$( find . -name .placeholder )
		if [[ -n "$placeholders" ]]; then

			echo "$tool"
			echo "=============================="

			# check git log
			if [[ $( git log -1 | grep "adding placeholders to empty directories" )	]]; then
				git --no-pager log -1

				# wait for manual check
				read -p "remove commit? [y/n]:" continue

				if [[ "$continue" == "y" ]]; then
					git reset --hard HEAD^
				fi

			fi

			echo ""
		fi

	done

done
