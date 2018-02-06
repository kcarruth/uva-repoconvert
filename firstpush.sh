#!/bin/bash
#
# push repo(s) up to github
# ONLY FOR INITIAL PUSHES

BASEDIR="/home/vagrant/repoconv"
WORKDIR="$BASEDIR/work"
REPODIR="$WORKDIR/combined"

BRANCHES="prod preprod test dev"

if [[ $1 ]]; then
	REPOS="$1"
else
	echo "error: no repo specified"
	exit
fi

for repo in $REPOS; do

	if [[ -d $REPODIR/$repo ]]; then
		cd $REPODIR/$repo

		githubrepo="collab-"$( echo $repo | sed "s/2\.//" | sed "s/\.x//" )

		echo ">"
		echo "> $repo"
		echo ">"

		if [[ $( git remote | egrep "(github|origin)" ) ]]; then
			# already done, skip
			continue
		fi

		git remote add github git@github.com:stacs/$githubrepo

		for branch in $BRANCHES; do

			if [[ $( git branch | grep "$branch" ) ]]; then
				git checkout $branch
				git push -u github $branch
			fi

		done # end for each branch
		
	fi

done # end for each repo
