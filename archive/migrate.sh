#!/bin/bash
#
# migrate.sh
#
START=$( date +%s )

BASEDIR="/home/vagrant/repoconv"
WORKDIR="$BASEDIR/work/archive"

SVNROOT="svn+ssh://atgsvn.itc.virginia.edu/sakai"
AUTHORSFILE="$BASEDIR/scripts/authors.txt"

INIT_OPTS=""
FETCH_OPTS="--no-follow-parent --authors-file=$AUTHORSFILE"

if [[ -d $WORKDIR/fromsvn ]]; then
	echo "error: work repo already exists"
	exit
fi

# migrate tool(s)
git svn init $INIT_OPTS --branches=REPLACEHERE $SVNROOT $WORKDIR/fromsvn

cd "$WORKDIR/fromsvn"

svnbranches="RIST,collab-state,kalturastats,sakaixfer"
sed -i "s|REPLACEHERE/\*|\{$svnbranches\}|" .git/config

git svn fetch $FETCH_OPTS

# generate branches
git for-each-ref --format="%(refname:short) %(objectname)" refs/remotes/origin |
while read branch ref; do
    gitbranch=`echo $branch | sed "s|origin/||g"`
    git branch $gitbranch $ref

	# in-branch work
	git checkout $gitbranch

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
	
	# move down into subdir treelevel
	if [[ $gitbranch == "RIST" ]]; then
		git filter-branch -f --subdirectory-filter trunk -- --all
	fi
	git filter-branch -f --index-filter 'git ls-files -s | sed "s#\t\"*#&'"$gitbranch"'/#" | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info && if [ -f $GIT_INDEX_FILE.new ]; then mv $GIT_INDEX_FILE.new $GIT_INDEX_FILE; fi' HEAD

	# now remove the placeholder commit
	if [[ $cleanup_commit -eq 1 ]]; then
		git reset --hard HEAD^
	fi

done # end while read branch	

git branch -D master

TIME=$( expr $(date +%s) - $START )
echo "Finished in $TIME seconds at $( date +%F\ %T )"
