#!/bin/bash
#
# generate some list files of what tools should be where

BASEDIR="/home/vagrant/repoconv"
WORKDIR="$BASEDIR/work/sakai"
OUTDIR="$WORKDIR/expected"

SVNROOT="svn+ssh://atgsvn.itc.virginia.edu/sakai"

cd $OUTDIR

# clean up any prev runs
ls | xargs rm -f

for svntool in $( svn ls $SVNROOT/uva-collab | sed "s|/$||" ); do  

	echo "> $svntool"

	if [[ -z $( svn ls $SVNROOT/uva-collab/$svntool | grep "branches" ) ]]; then
		continue
	fi

	for svnbranch in $( svn ls $SVNROOT/uva-collab/$svntool/branches | egrep "^sakai_[^_]+_" | sed "s|/$||" ); do

		#echo "$svnbranch"

		version=$( echo $svnbranch | sed -r "s/sakai_([^_]+)_.+$/\1/" )
		status=$( echo $svnbranch | sed -r "s/sakai_[^_]+_(.+)/\1/" )
	
		outfile="${version}_${status}"
		#echo "$outfile"

		echo "$svntool" >> $outfile

	done # end each svnbranch	   

done #end foreach svn tool
