#!/bin/bash
#
#

START=$( date +%s )

BASE="/home/vagrant/repoconv"
WORK="$BASE/work/sakai/tools"

SVN_ROOT="svn+ssh://atgsvn.itc.virginia.edu/sakai/uva-collab"
AUTHORS_FILE="$BASE/authors/combined.txt"

INIT_OPTS=""
#INIT_OPTS="--no-metadata"
FETCH_OPTS="--no-follow-parent --authors-file=$AUTHORS_FILE"
CLONE_OPTS="$SVN_INIT_OPTS $SVN_FETCH_OPTS"

if [[ $1 ]]; then
	if [[ "$1" == "--all" ]]; then
		TOOLS=$( svn ls $SVN_ROOT | sed "s|/$||" )
	else
		TOOLS="$1"
	fi
else
	echo "error: no tool (or --all) specified."
	exit
fi

for TOOL in $TOOLS; do

	echo "====================================="
	echo "TOOL: $TOOL"
	echo "====================================="

	# get list of branches to migrate
	for b in $( svn ls $SVN_ROOT/$TOOL/branches | egrep "sakai_" | sed "s/\/$//" ); do
		if [[ -n $branches ]]; then
			branches="$branches,"
		fi
		branches="$branches$b"
	done

	# migrate tool
	git svn init $INIT_OPTS --branches=REPLACEHERE $SVN_ROOT/$TOOL $BASE/$WORK/$TOOL
	
	cd "$BASE/$WORK/$TOOL"
	sed -i "s|REPLACEHERE/\*|branches/\{$branches\}|" .git/config
	
	git svn fetch $FETCH_OPTS

	# generate branches
	git for-each-ref --format="%(refname:short) %(objectname)" refs/remotes/origin | grep -v "^origin/SAK" | grep -v "@.*$" |
	while read branch ref; do
	    branch=`echo $branch | sed "s|origin/||g"`
	    git branch $branch $ref
	
		# in-branch work
		git checkout $branch
	
		# import svn:ignore
		IGNORE=$( git svn show-ignore 2>/dev/null | grep -v "^#" | grep -v "^$" )
		if [[ $IGNORE != "" ]]; then
			if [[ ! -d "$BASE/work/ignore/$TOOL" ]]; then
				mkdir "$BASE/work/ignore/$TOOL"
			fi
			echo "$IGNORE" > "${BASE}/work/ignore/${TOOL}/${branch}"
		fi

		# need to populate empty dirs, otherwise subsequent filter-branch doesn't move everything	
		emptydirs=$( find . -type d -empty | grep -v "/\.git/" )
		if [[ -n $emptydirs ]]; then
			for emptydir in $emptydirs; do
				touch "$emptydir/.placeholder"
				git add "$emptydir/.placeholder"
			done
			echo " - adding placeholders to empty directories" >> commitmsg
		fi

		cleanup_commit="0"	
		if [[ -n $( git diff-index --name-only HEAD -- ) ]]; then
			git commit -m "temporary placeholders for empty dirs"
			cleanup_commit="1"
		fi	
	
		# shift down a level (prep for future merges into single repo)
		git filter-branch -f --index-filter 'git ls-files -s | sed "s#\t\"*#&'"$TOOL"'/#" | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info && if [ -f $GIT_INDEX_FILE.new ]; then mv $GIT_INDEX_FILE.new $GIT_INDEX_FILE; fi' HEAD
		#git filter-branch -f --index-filter 'git ls-files -s | sed "s#\t\"*#&'"$TOOL"'/#" | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info && mv $GIT_INDEX_FILE.new $GIT_INDEX_FILE || true' HEAD

		# now remove the placeholder commit
		if [[ $cleanup_commit -eq 1 ]]; then
			git reset --hard HEAD^
		fi

		#git branch -r -d "origin/$branch"
	done
	
	git branch -D master
	
	cd $BASE

# end of main for loop
done

TIME=$( expr $(date +%s) - $START )
echo "Finished in $TIME seconds at $( date +%F\ %T )"
