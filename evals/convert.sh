#!/bin/bash
#
# evals/convert.sh
#
# convert evals projects into archival git repo

START=$( date +%s )

BASEDIR="/home/vagrant/repoconv"
WORKDIR="$BASEDIR/work/evals"

if [[ ! -d $WORKDIR ]]; then
	mkdir -p $WORKDIR
fi

INITOPTS=""
FETCHOPTS="--no-follow-parent --authors-file=$BASEDIR/scripts/authors.txt"
CLONEOPTS="$INITOPTS $FETCHOPTS"

SVNROOT="svn+ssh://atgsvn.itc.virginia.edu/sakai"

#
# migrate
#
for project in "course-evals2" "course-evals-taking"; do

  if [[ -d $WORKDIR/$project.fromsvn ]]; then
  	echo "migrated repo $project.fromsvn already exists, skipping..."
  else

  	# do the clone
  	git svn clone $CLONEOPTS --trunk="trunk" $SVNROOT/$project $WORKDIR/$project.fromsvn
  	
  	# fixup
  	cd $WORKDIR/$project.fromsvn
  	
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
  	
  	# shift everything down to a subdir
  	git filter-branch -f --index-filter 'git ls-files -s | sed "s#\t\"*#&'"$project"'/#" | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info && if [ -f $GIT_INDEX_FILE.new ]; then mv $GIT_INDEX_FILE.new $GIT_INDEX_FILE; fi' HEAD
  	
  	# now remove the placeholder commit
  	if [[ $cleanup_commit -eq 1 ]]; then
  		git reset --hard HEAD^
  	fi
  	
  fi

done

#
# merge into combined repo
#
if [[ -d $WORKDIR/evals.combined ]]; then
	echo "combined repo evals.combined already exists, skipping merge..."
else

	mkdir "$WORKDIR/evals.combined"
	cd "$WORKDIR/evals.combined"
	git init
	git commit --allow-empty -m "initializing $repo repository"

  for remote in "course-evals2" "course-evals-taking"; do
  	# add remote repo
  	git remote add $remote $WORKDIR/$remote.fromsvn
  	git fetch $remote

	  git rebase --committer-date-is-author-date $remote/master

	  # cleanup
	  git remote rm $remote
  done

fi

TIME=$( expr $(date +%s) - $START )
echo "Finished in $TIME seconds at $( date +%F\ %T )"
