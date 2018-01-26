#!/bin/bash
#
# combine disparate tool repos into one big repo

START=$( date +%s )

#VERSIONS="2-5-x 2-6-x 2-7-x 2-8-x 2-9-x 10-x"
VERSIONS="2-5-x"
STATES="dev test preprod prod"

BASE="/home/vagrant/repoconv"
TOOLS="$BASE/work/toolrepos"
WORK="$BASE/work/combined"
SVNROOT="svn+ssh://atgsvn.itc.virginia.edu/sakai"

for VERSION in $VERSIONS; do

	repo=$( echo $VERSION | sed "s/-/./g" )

	# create empty repo
	if [[ ! -d "$WORK/$repo" ]]; then
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

			# if nothing got added, then that branch didn't exist (ex: 2-5-x_dev/preprod)
			if [[ $( ls ) ]]; then

				# export and commit top-level build pom
				svn export $SVNROOT/uva-collab-build/branches/$branch/pom.xml pom.xml
				git add pom.xml
				git commit -m "$repo/$STATE: importing top-level build pom"

			else

				git checkout master
				git branch -D $STATE

			fi

		done # end foreach $STATES

	fi # end if ! repodir

done # end foreach $REPOS

# print runtime
FINISH=$( date +%s )
TIME=$( expr $FINISH - $START )
echo "Finished in $TIME seconds"
