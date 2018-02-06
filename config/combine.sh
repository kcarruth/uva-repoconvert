#!/bin/bash

START=$( date +%s )

BASEDIR="/home/vagrant/repoconv"
WORKDIR="$BASEDIR/work/config"

SVNROOT="svn+ssh://atgsvn.itc.virginia.edu/sakai/uva-collab-config"

# we'll have a repo from github to start with, which has branches & existing stuff in it
if [[ ! -d $WORKDIR/combined ]]; then
	echo "error: git repo not checked out"
	exit
fi

# list remote branches
cd $WORKDIR/fromsvn
rbranches=$( git branch | sed "s/^\.\.//" )

# merge in dirs into each local branch
cd $WORKDIR/combined

# add remote repo
git remote add fromsvn $WORKDIR/fromsvn
git fetch fromsvn

for lbranch in $( git branch | sed "s/^\.\.//" ); do
	git checkout $lbranch

	for rbranch in $rbranches; do

		git rebase --committer-date-is-author-date fromsvn/$rbranch

	done

done # end while read branch	

# cleanup
git remote rm fromsvn

TIME=$( expr $(date +%s) - $START )
echo "Finished in $TIME seconds at $( date +%F\ %T )"
