#!/bin/bash
#
# migrate.sh

START=$( date +%s )

BASEDIR="/home/vagrant/repoconv"
WORKDIR="$BASEDIR/work/puppet"

INITOPTS=""
FETCHOPTS="--no-follow-parent --authors-file=$BASEDIR/authors/combined.txt"

SVNROOT="svn+ssh://atgsvn.itc.virginia.edu/puppet"

#
# puppet 'archive' (old-environment configs)
#
if [[ -d $WORKDIR/archive ]]; then
	echo "archive repo already exists... skipping"
else

	git svn init $INITOPTS --trunk="trunk" --branches="REPLACEME" $SVNROOT $WORKDIR/archive

	cd $WORKDIR/archive
	branches="centos7,cus-chroot,test"
	sed -i "s|REPLACEME/\*|branches/\{$branches\}|" .git/config

  git svn fetch $FETCHOPTS

	# generate branches
	git for-each-ref --format="%(refname:short) %(objectname)" refs/remotes/origin | grep -v "^origin/SAK" | grep -v "@.*$" |
	while read branch ref; do
    gitbranch=`echo $branch | sed "s|origin/||g"`
    git branch $gitbranch $ref
	
		# in-branch work
		git checkout $gitbranch
	
		#git branch -r -d "origin/$branch"
	done
	
	git branch -D master

fi

#
# puppet current
#
if [[ -d $WORKDIR/current ]]; then
	echo "current puppet repo already exists... skipping"
else

	git svn clone $CLONEOPTS --trunk="branches/docker-prod" $SVNROOT $WORKDIR/current

	if [[ 1 -eq 0 ]]; then # block comment
	# create test branch, add outstanding commits
	cd $WORKDIR/current
	git checkout -b test

	# (rev list pulled from stacs-misc2 and 'svnmerge avail'
	for rev in 3523 3525 3527; do

		prev=$( expr $rev - 1 )

		comdate=$( svn info -r$rev --show-item last-changed-date $SVNURL )
        message=$( svn log -r$rev $SVNURL | egrep -v "^-|^$|^r[0-9]+" )

		if [[ -n "$comdate" && -n "$message" ]]; then
			svn diff -r$prev:$rev $SVNURL | patch -p0
			GIT_COMMITTER_DATE="$comdate" git commit -m "$message" --date="$comdate"
		fi

	done
	fi # end block comment

fi

TIME=$( expr $(date +%s) - $START )
echo "Finished in $TIME seconds at $( date +%F\ %T )"
