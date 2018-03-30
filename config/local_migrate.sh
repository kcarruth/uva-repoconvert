#!/bin/bash
#
# migrate.sh

START=$( date +%s )

BASEDIR="/home/vagrant/repoconv"
WORKDIR="$BASEDIR/work/config"

SVNROOT="svn+ssh://atgsvn.itc.virginia.edu/sakai/uva-collab-config"
AUTHORSFILE="$BASEDIR/authors/combined.txt"

INIT_OPTS=""
FETCH_OPTS="--no-follow-parent --authors-file=$AUTHORSFILE"
CLONE_OPTS="$INIT_OPTS $FETCH_OPTS"

svnbranches=""
# get list of branches to migrate
for b in $( svn ls $SVNROOT/branches | sed -r "s|/$||" ); do
	if [[ -n $svnbranches ]]; then
		svnbranches="$svnbranches,"
	fi
	svnbranches="$svnbranches$b"
done


#git svn clone $CLONE_OPTS --trunk="branches/sakai_11-x_$svnbranch" "$SVNROOT" $WORKDIR/branches/$svnbranch
# migrate tool
git svn init $INIT_OPTS --branches=REPLACEHERE $SVNROOT $WORKDIR/fromsvn

cd "$WORKDIR/fromsvn"
sed -i "s|REPLACEHERE/\*|branches/\{$svnbranches\}/properties|" .git/config

git svn fetch $FETCH_OPTS

# generate branches
git for-each-ref --format="%(refname:short) %(objectname)" refs/remotes/origin |
while read branch ref; do
    gitbranch=`echo $branch | sed "s|origin/sakai_11-x_||g"`
    git branch $gitbranch $ref

	# in-branch work
	git checkout $gitbranch

	# move down one two levels
	#git filter-branch -f --index-filter 'git ls-files -s | sed "s#\t\"*#&'local/"$gitbranch"'/#" | GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info && if [ -f $GIT_INDEX_FILE.new ]; then mv $GIT_INDEX_FILE.new $GIT_INDEX_FILE; fi' HEAD

done # end while read branch	

git branch -D master

TIME=$( expr $(date +%s) - $START )
echo "Finished in $TIME seconds at $( date +%F\ %T )"
