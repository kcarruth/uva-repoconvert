#!/bin/bash
#
# after migration / combination process is done, do some basic checking for completion

BASEDIR="/home/vagrant/repoconv"
WORKDIR="$BASEDIR/work"
TOOLDIR="$WORKDIR/tools"
REPODIR="$WORKDIR/combined"

SVNROOT="svn+ssh://atgsvn.itc.virginia.edu/sakai"

if [[ $1 ]]; then
	REPOS="$1"
else
	REPOS=$( ls $REPODIR )
fi

svntools=$( svn ls $SVNROOT/uva-collab | sed "s|/$||" )

# verify top poms and last commits match up
for gitrepo in $REPOS; do

	if [[ ! -d $REPODIR/$gitrepo/.git ]]; then
		echo "error: $gitrepo is not a valid git repo"
		continue
	fi

	cd $REPODIR/$gitrepo
	svnversion=$( echo $gitrepo | sed "s/\./-/g" )

	if [[ "1" == "0" ]]; then
	for gitbranch in $( git branch | sed "s/^..//" ); do

		git checkout $gitbranch 2>/dev/null

		if [[ ! -f pom.xml ]]; then
			echo "MISSING TOP POM: $gitrepo / $gitbranch"
		fi

		svnbranch="sakai_${svnversion}_${gitbranch}"

		for tool in $( find . -maxdepth 1 -type d | egrep -v "^\.$" | sed "s|^\./||" ); do

			last_gitcommit=$( git log -1 $tool | grep "git-svn-id" | sed -r "s/^[^@]*@([0-9]+) .*$/\1/" )
			last_svncommit=$( svn log -q -l 1 $SVNROOT/uva-collab/$tool/branches/$svnbranch | egrep "^r" | sed -r "s/^r([0-9]+) \|.*$/\1/" )

			echo "git: $last_gitcommit"
			echo "svn: $last_svncommit"

			if [[ "$last_gitcommit" != "$last_svncommit" ]]; then
				echo "REV MISMATCH FOUND: $gitrepo / $gitbranch / $tool"
				echo "> last git rev: $last_gitcommit"
				echo "> last svn rev: $last_svncommit"
			fi

		done # end foreach tool

	done # end foreach git branch
	fi # shitty block comment

	# verify each appropriate tool got imported and combined
	for svntool in $svntools; do 

		echo ">>"
		echo ">> $gitrepo / $svntool"
		echo ">>"

		for svnbranch in $( svn ls $SVNROOT/uva-collab/$svntool/branches | grep "sakai_${svnversion}_" ); do

			gitbranch=$( echo $svnbranch | sed "s/sakai_${svnversion}_//" | sed "s|/$||" ) # dev/test/etc

			if [[ $( git branch | sed "s/^..//" | grep "$gitbranch" ) ]]; then			

				git checkout $gitbranch 2>/dev/null

				if [[ ! -d $svntool ]]; then
					echo "MISSING TOOL: $svntool not found in $gitrepo / $gitbranch"
				fi
			else 
				echo "MISSING BRANCH: $gitbranch missing from $gitrepo"
			fi			

		done # end each svnbranch		

	done #end foreach svn tool

done # end foreach git repo

