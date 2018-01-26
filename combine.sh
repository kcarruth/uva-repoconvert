#!/bin/bash
#
# combine disparate tool repos into one big repo

VERSIONS="2-5-x 2-6-x 2-7-x 2-8-x 2-9-x 10-x"
STATES="dev test preprod prod"

BASE="/home/vagrant/repoconv"
TOOLS="$BASE/work/toolrepos"
WORK="$BASE/work/combined"

for VERSION in $VERSIONS; do

	repo=$( echo $VERSION | sed "s/-/./g" )

	# create empty repo
	mkdir "$WORK/$repo"
	cd "$WORK/$repo"
	git init
	git commit --allow-empty -m "initializing $repo repository"

	# create branch for each prodstatus
	for STATE in $STATES; do
		git checkout master
		git checkout -b $STATE

		branch="sakai_${VERSION}_${STATE}"

		# loop through tool dirs, importing
		for tool in $( ls $TOOLS ); do

			if [[ $( cd $TOOLS/$tool; git branch | grep "$branch") ]]; then

				git remote add -t "$branch" $tool $TOOLS/$tool
				git fetch $tool
				git merge -m "$repo/$STATE: importing $tool" --commit "$tool/$branch"
				git remote rm $tool

			fi

		done # end foreach TOOL

	done # end foreach $STATES

done # end foreach $REPOS
