#!/bin/bash
#
# uva-config.sh

START=$( date +%s )

BASEDIR="/home/vagrant/repoconv"
WORKDIR="$BASEDIR/work/config"

if [[ ! -d $WORKDIR ]]; then
	mkdir -p $WORKDIR
fi

INITOPTS=""
FETCHOPTS="--no-follow-parent --authors-file=$BASEDIR/authors/combined.txt"
CLONEOPTS="$INITOPTS $FETCHOPTS"

SVNROOT="svn+ssh://atgsvn.itc.virginia.edu/sakai/uva-collab/uva-config/branches/sakai_11-x_dev/server"

#
# migrate
#
trunk="properties"
if [[ -d $WORKDIR/$trunk.fromsvn ]]; then
	echo "migrated repo $trunk.fromsvn already exists, skipping..."
else

	# do the clone
	git svn clone $CLONEOPTS --trunk="$trunk" $SVNROOT $WORKDIR/$trunk.fromsvn
	
	# fixup
	cd $WORKDIR/$trunk.fromsvn
	
	# need to populate empty dirs, otherwise subsequent filter-branch doesn't move everything	
	emptydirs=$( find . -type d -empty | grep -v "/\.git/" )
	if [[ -n $emptydirs ]]; then
		for emptydir in $emptydirs; do
			touch "$emptydir/.placeholder"
			git add "$emptydir/.placeholder"
		done
	fi
	
	cleanup_commit="0"	
	if [[ -n $( git diff-index --name-only HEAD -- ) ]]; then
		git commit -m "temporary placeholders for empty dirs"
		cleanup_commit="1"
	fi
	
	# shift everything down to a "common" dir
	topdir="common"
	git filter-branch -f --index-filter 'git ls-files -s | sed "s#\t\"*#&'"$topdir"'/#" | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info && if [ -f $GIT_INDEX_FILE.new ]; then mv $GIT_INDEX_FILE.new $GIT_INDEX_FILE; fi' HEAD
	
	# now remove the placeholder commit
	if [[ $cleanup_commit -eq 1 ]]; then
		git reset --hard HEAD^
	fi
	
fi

#
# merge into migrated uva-collab-config repo
#
if [[ -d $WORKDIR/$trunk.combined ]]; then
	echo "combined repo $trunk.combined already exists, skipping merge..."
else

	if [[ ! -d $WORKDIR/combined ]]; then
		echo "ERROR: uva-collab-config repo missing; run that process first?"
	else

		# copy repo
		#cp -pR $WORKDIR/combined $WORKDIR/$trunk.combined
		git clone git@github.com:stacs/collab-config $WORKDIR/$trunk.combined
		cd $WORKDIR/$trunk.combined
		
		# add remote repo
		git remote add uva-config $WORKDIR/$trunk.fromsvn
		git fetch uva-config

		git rebase --committer-date-is-author-date uva-config/master

		# cleanup
		git remote rm uva-config

	fi

fi

TIME=$( expr $(date +%s) - $START )
echo "Finished in $TIME seconds at $( date +%F\ %T )"
