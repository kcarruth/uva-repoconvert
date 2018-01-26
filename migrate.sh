#!/bin/bash
#
#

START=$( date +%s )

BASE="/home/vagrant/repoconv"
WORK="work/toolrepos"

SVN_CLONE_OPTS="--no-follow-parent"
AUTHORS_FILE="authors/combined.txt"
SVN_ROOT="svn+ssh://atgsvn.itc.virginia.edu/sakai/uva-collab"

if [[ $1 ]]; then
	TOOLS="$1"
else
	TOOLS=$( svn ls $SVN_ROOT | sed "s|/$||" )
fi

for TOOL in $TOOLS; do

	if [[ $TOOL == "" ]]; then
		echo "error: no tool specified."
		exit
	fi
	
	# migrate tool
	git svn clone $SVN_CLONE_OPTS --branches=/branches --tags=/vendor --authors-file=$AUTHORS_FILE $SVN_ROOT/$TOOL $BASE/$WORK/$TOOL
	
	cd "$BASE/$WORK/$TOOL"
	
	# generate tags
	git for-each-ref --format="%(refname:short) %(objectname)" refs/remotes/origin/tags |
	while read tag ref; do
	    tag=`echo $tag | sed "s|origin/tags/||g"`
	    comment="$(git log -1 --format=format:%B $ref)"
	    git tag -a $tag -m "$comment" $ref
	    git branch -r -d "origin/tags/$tag"
	done
	
	# generate branches
	git for-each-ref --format="%(refname:short) %(objectname)" refs/remotes/origin | grep -v "^origin/SAK" | grep -v "@.*$" |
	while read branch ref; do
		echo "svn-to-git conversion for $TOOL/$branch: " > commitmsg
	
	    branch=`echo $branch | sed "s|origin/||g"`
	    git branch $branch $ref
	
		# in-branch work
		git checkout $branch
	
		# import svn:ignore
		IGNORE=$( git svn show-ignore 2>/dev/null | grep -v "^#" | grep -v "^$" )
		if [[ $IGNORE != "" ]]; then
			echo "$IGNORE" > .gitignore
			git add .gitignore
			echo " - converting svn:ignore props" >> commitmsg
			#git commit -m "converting svn:ignore for $TOOL/$branch"
		fi
	
		emptydirs=$( find . -type d -empty | grep -v "/\.git/" )
		if [[ -n $emptydirs ]]; then
			for emptydir in $emptydirs; do
				touch "$emptydir/.placeholder"
				git add "$emptydir/.placeholder"
			done
			" - adding placeholders to empty directories" >> commitmsg
		fi
	
		if [[ -n $( git diff-index --name-only HEAD -- ) ]]; then
			git commit -F commitmsg
		fi	
		rm commitmsg
	
		# shift down a level (prep for future merges into single repo)
		git filter-branch -f --index-filter 'git ls-files -s | sed "s#\t\"*#&'"$TOOL"'/#" | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info && if [ -f $GIT_INDEX_FILE.new ]; then mv $GIT_INDEX_FILE.new $GIT_INDEX_FILE; fi' HEAD
		#git filter-branch -f --index-filter 'git ls-files -s | sed "s#\t\"*#&'"$TOOL"'/#" | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info && mv $GIT_INDEX_FILE.new $GIT_INDEX_FILE || true' HEAD
	
		#git branch -r -d "origin/$branch"
	done
	
	git branch -D master
	
	cd $BASE

# end of main for loop
done

FINISH=$( date +%s )

TIME=$( expr $FINISH - $START )

echo "Finished in $TIME seconds"
