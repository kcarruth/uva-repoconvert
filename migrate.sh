#!/bin/bash
#
#

START=$( date +%s )

TOOL="$1"
BACK="~/repoconv"

PARENTS_OPT="--no-follow-parent"
AUTHORS_FILE="authors/combined.txt"

# migrate tool
git svn clone $PARENTS_OPT --branches=/branches --tags=/vendor --authors-file=$AUTHORS_FILE svn+ssh://atgsvn.itc.virginia.edu/sakai/uva-collab/$TOOL repos/$TOOL

cd repos/$TOOL

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
    branch=`echo $branch | sed "s|origin/||g"`
    git branch $branch $ref

	# in-branch work
	git checkout $branch

	# import svn:ignore
	IGNORE=$( git svn show-ignore 2>/dev/null | grep -v "^#" | grep -v "^$" )
	if [[ $IGNORE != "" ]]; then#
		echo "$IGNORE" > .gitignore
		git add .gitignore
		git commit -m "converting svn:ignore for $branch"
	fi

	# shift down a level
	#git filter-branch --index-filter "git ls-files -s | sed 's-\t\"*-&$TOOL/-' | GIT_INDEX_FILE=\"$GIT_INDEX_FILE.new\" git update-index --index-info && mv \"$GIT_INDEX_FILE.new\" \"$GIT_INDEX_FILE\" || true" HEAD

	#git branch -r -d "origin/$branch"
done

#git branch -D master

cd $BACK

FINISH=$( date +%s )

TIME=$( expr $FINISH - $START )

echo "Finished in $TIME seconds"
