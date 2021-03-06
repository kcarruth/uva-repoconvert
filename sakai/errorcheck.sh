#!/bin/bash
#
# after migration / combination process is done, do some basic checking for completion

START=$( date +%s )

BASEDIR="/home/vagrant/repoconv"
WORKDIR="$BASEDIR/work/sakai"
TOOLDIR="$WORKDIR/tools"
REPODIR="$WORKDIR/combined"

SVNROOT="svn+ssh://atgsvn.itc.virginia.edu/sakai"

declare -a IGNOREMSGS
IGNOREMSGS=(
	"initializing svnmerge from"
	"uninitializing old svnmerge watches from"
	"Initialized merge tracking via \"svnmerge\""
	"Removed merge tracking for \"svnmerge\" for"
	"hiding target directories from svn"
	"hiding target dirs from svn"
	"hiding target dirs for"
	"hiding [^ ]+ target dirs"
	"Cleanup Merge of trunk into"
	"delete the [^ ]+ prod SVN properties"
)

if [[ $1 ]]; then
	REPOS="$1"
else
	REPOS=$( ls $REPODIR )
fi

# verify top poms and last commits match up
for gitrepo in $REPOS; do

	echo "starting $gitrepo"
	echo "=============================="

	if [[ ! -d $REPODIR/$gitrepo/.git ]]; then
		echo "error: $gitrepo is not a valid git repo"
		continue
	fi

	cd $REPODIR/$gitrepo
	svnversion=$( echo $gitrepo | sed "s/\./-/g" )

	# ensure all branches that should exist do exist
	echo "> checking for missing branches..."
	for eb in $( ls $WORKDIR/expected | grep "${svnversion}_" | sed -r "s/^[^_]+_//" ); do
		if [[ ! $( git branch | sed "s/..//" | grep "$eb" ) ]]; then
			echo "  > missing branch $gitrepo / $eb"
		fi
	done

	echo ""

	echo "> checking branch contents..."
	for gitbranch in $( git branch | sed "s/^..//" ); do
	#for gitbranch in prod; do

		git checkout $gitbranch 1>/dev/null 2>&1

		echo "  > $gitbranch: checking for missing pom..."
		if [[ ! -f pom.xml ]]; then
			echo "  > missing top-pom in $gitrepo / $gitbranch"
		fi

		echo ""
		echo "  > $gitbranch: comparing latest commits"

		for tool in $( find . -maxdepth 1 -type d | grep -v "\.git" | egrep -v "^\.$" | sed "s|^\./||" | sort ); do
		#for tool in signup; do

			if [[ $( svn ls $SVNROOT/uva-collab/$tool 2>/dev/null | grep "branches" ) ]]; then
				#echo "    > checking $tool..."

				svnbranch="$SVNROOT/uva-collab/$tool/branches/sakai_${svnversion}_${gitbranch}"

				last_gitcommit=$( git log -1 $tool | grep "git-svn-id" | sed -r "s/^[^@]*@([0-9]+) .*$/\1/" )
				last_svncommit=$( svn log -q -l 1 $svnbranch | egrep "^r" | sed -r "s/^r([0-9]+) \|.*$/\1/" )

				if [[ $last_gitcommit -eq $last_svncommit ]]; then
					# if they match, no need to keep checking
					continue
				fi

				# git conversion ignored svnmerge inits and the like, so accomodate
				declare -a svnrevs					
				mapfile -t svnrevs < <( svn log -q -r${last_svncommit}:${last_gitcommit} $svnbranch | egrep "^r" | sed -r "s/^r([0-9]+) \|.*$/\1/" )

				for ((s=0; s<${#svnrevs[@]}; s++)); do
					svnrev="${svnrevs[$s]}"
					ignorecommit="0"
					fullmsg=$(svn log $svnbranch -r$svnrev)
					for ((i=0; i< ${#IGNOREMSGS[@]}; i++)) do
						imsg="${IGNOREMSGS[$i]}"
						if [[ $( echo "$fullmsg" | egrep "$imsg") ]]; then
							ignorecommit="1"
							break
						fi
					done

					# check for svnmerge
					if [[ $ignorecommit -eq 0 ]]; then
						last_svncommit="$svnrev"
						break
					fi
				done

				#echo "git: $last_gitcommit"
				#echo "svn: $last_svncommit"

				if [[ "$last_gitcommit" != "$last_svncommit" ]]; then
					echo "      > rev mismatch $gitrepo / $gitbranch / $tool"
					echo "        > last git rev: $last_gitcommit"
					echo "        > last svn rev: $last_svncommit"
				fi

			fi # end if /branches exists in svn
		done # end foreach tool

		echo ""
		echo "    > checking for repo completion..."
		
		# check that each repo is complete
		for svntool in $( cat $WORKDIR/expected/${svnversion}_${gitbranch} ); do

			if [[ ! -d $svntool ]]; then
				echo "      > missing tool: $svntool not found in $gitrepo / $gitbranch"
			fi

		done # end each svn tool

		echo ""

	done # end foreach git branch

	echo ""
	echo ""

done # end foreach git repo

TIME=$( expr $(date +%s) - $START )
echo "Finished in $TIME seconds at $( date +%F\ %T )"
