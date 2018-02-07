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
#git init $WORKDIR/combined
mkdir -p $WORKDIR/combined
cd $WORKDIR/combined
git init
git commit --allow-empty -m "initializing archive repository"

# add remote repo
git remote add fromsvn $WORKDIR/fromsvn
git fetch fromsvn

# merge in remote repo branches
for rbranch in $rbranches; do
	echo "$rbranch"

	git rebase --committer-date-is-author-date fromsvn/$rbranch

done


# cleanup
git remote rm fromsvn

TIME=$( expr $(date +%s) - $START )
echo "Finished in $TIME seconds at $( date +%F\ %T )"
