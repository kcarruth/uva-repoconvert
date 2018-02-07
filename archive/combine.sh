#!/bin/bash
#
# combine.sh

START=$( date +%s )

BASEDIR="/home/vagrant/repoconv"
WORKDIR="$BASEDIR/work/archive"

# we'll have a repo from github to start with, which has branches & existing stuff in it
if [[ -d $WORKDIR/combined ]]; then
	echo "error: git repo already exists"
	exit
fi

# list remote branches
cd $WORKDIR/fromsvn
rbranches=$( git branch | sed "s/^..//" )

# create empty repo
git init $WORKDIR/combined

# merge in dirs into each local branch
cd $WORKDIR/combined

# add remote repo
git remote add fromsvn $WORKDIR/fromsvn
git fetch fromsvn

for rbranch in $rbranches; do
	echo "$rbranch"

	git rebase --committer-date-is-author-date fromsvn/$rbranch

done


# cleanup
#git remote rm fromsvn

TIME=$( expr $(date +%s) - $START )
echo "Finished in $TIME seconds at $( date +%F\ %T )"
