#!/bin/bash
#
# combine.sh

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

# create empty repo
git init $WORKDIR/combined

# merge in dirs into each local branch
cd $WORKDIR/combined

# add remote repo
git remote add fromsvn $WORKDIR/fromsvn
git fetch fromsvn

rbranches=$( git branch | sed "s/^\.\.//" )
for rbranch in $rbranches; do

	git rebase --committer-date-is-author-date fromsvn/$rbranch

done

# rename branch to test (starting there) 
git branch -m master test

# gitignore
echo "override.properties" > local/.gitignore
git add local/.gitignore
git commit -m "setting ignore for override.properties files"

# cleanup
git remote rm fromsvn

TIME=$( expr $(date +%s) - $START )
echo "Finished in $TIME seconds at $( date +%F\ %T )"
