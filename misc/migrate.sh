#!/bin/bash
#
# migrate.sh

BASEDIR="/home/vagrant/repoconv"
WORKDIR="$BASEDIR/work/misc"

INITOPTS=""
FETCHOPTS="--no-follow-parent --authors-file=$BASEDIR/scripts/authors.txt"
CLONEOPTS="$INITOPTS $FETCHOPTS"

SVNROOT="svn+ssh://atgsvn.itc.virginia.edu/misc"

trunks=$( svn ls $SVNROOT | sed "s|/$||" )

for trunk in $trunks; do

	git svn clone $CLONEOPTS --trunk="$trunk" $SVNROOT $WORKDIR/$trunk

done
