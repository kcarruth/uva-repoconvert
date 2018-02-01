#!/bin/bash
#
# combine disparate tool repos into one big archival repo (for prev versions of sakai)

START=$( date +%s )

if [[ $1 ]]; then
	VERSIONS="$1"
else
	VERSIONS="2-5-x 2-6-x 2-7-x 2-8-x 2-9-x 10-x"
fi

STATES="dev test preprod prod"

BASE="/home/vagrant/repoconv"
TOOLS="$BASE/work/tools"
IGNORE="$BASE/work/ignore"
WORK="$BASE/work/combined"
SVNROOT="svn+ssh://atgsvn.itc.virginia.edu/sakai"

for VERSION in $VERSIONS; do

	repo=$( echo $VERSION | sed "s/-/./g" )

	# create empty repo
	if [[ -d "$WORK/$repo" ]]; then
		echo "error: combined repo already exists. previous run perhaps?"
		continue
	else
		mkdir "$WORK/$repo"
		cd "$WORK/$repo"
		git init
		git commit --allow-empty -m "initializing $repo repository"

		# create branch for each prodstatus
		for STATE in $STATES; do

			echo ">"
			echo "> $VERSION/$STATE"
			echo ">"

			# check out master (blank) and clear up any lingering crap (in case of svn errors or the like)
			git checkout master
			git clean -f

			git checkout -b $STATE

			if [[ -f .gitignore ]]; then
				rm .gitignore
			fi

			branch="sakai_${VERSION}_${STATE}"

			# loop through tool dirs, importing
			#for tool in $( ls $TOOLS ); do
			for tool in assignment announcement; do

				if [[ $( cd $TOOLS/$tool; git branch | grep "$branch") ]]; then

					echo ">>"
					echo ">> $VERSION / $STATE / $tool"
					echo ">>"

					git remote add -t "$branch" $tool $TOOLS/$tool
					git fetch $tool
					#git merge -m "$repo/$STATE: importing $tool" --commit "$tool/$branch"
					git rebase --committer-date-is-author-date $tool/$branch
					#git pull --rebase $tool
					git remote rm $tool

					# converted svn:ignore
					if [[ -f $IGNORE/$tool/$branch ]]; then
						for i in $( cat $IGNORE/$tool/$branch | sed "s|^/||" ); do
							echo "$tool/$i" >> .gitignore
						done
					fi

				fi

			done # end foreach TOOL

			if [[ $( ls ) ]]; then

				# find top-level build pom 
				#  (in some sakai versions, it's nested under an additional "tools" subdir)
				nested="false"
				svnpom="$SVNROOT/uva-collab-build/branches/$branch/pom.xml"
				if [[ ! $( svn ls $svnpom 2>/dev/null ) ]]; then
					svnpom="$SVNROOT/uva-collab-build/branches/$branch/tools/pom.xml"
					nested="true"
				fi

				# export top-level pom
				svn export $svnpom pom.xml

				# fix up nested pom w/ kernel & pure-poms (separated in svn to avoid full builds)
				if [[ "$nested" == "true" ]]; then
					line=0
					if [[ $( grep "<id>full</id>" pom.xml ) ]]; then
						line=$( sed -n '/<id>full</,/<modules>/{=;p}' pom.xml | sed '{N;s/\n/ /}' | grep "<modules>" | sed -r "s/[^0-9]+$//" )
					elif [[ $( grep "<id>all</id>" pom.xml ) ]]; then
						line=$( sed -n '/<id>all</,/<modules>/{=;p}' pom.xml | sed '{N;s/\n/ /}' | grep "<modules>" | sed -r "s/[^0-9]+$//" )
					fi
					if [[ $line -gt 0 ]]; then
						if [[ $( svn ls $SVNROOT/uva-collab/pure-poms/branches/$branch 2>/dev/null ) ]]; then
							sed -i "$line a \                <module>pure-poms</module>" pom.xml
						fi
						sed -i "$line a \                <module>kernel</module>" pom.xml
					fi
				fi

				# add/commit
				git add pom.xml
				commitmsg="importing top-level build pom"

				# add ignores
				if [[ -f .gitignore ]]; then
					git add .gitignore
					commitmsg="$commitmsg and converted svn:ignore props"
				fi

				# set date to past to fit w/ rest of repo
				comdate=$( svn info --show-item last-changed-date $svnpom )
				GIT_COMMITTER_DATE="$comdate" git commit -m "$commitmsg" --date="$comdate"

			else

				# if nothing got added, then that branch didn't exist (ex: 2-5-x_dev/preprod)
				git checkout master
				git branch -D $STATE

			fi

		done # end foreach $STATES

		# delete master
		if [[ $( git branch | grep -v "master" ) ]]; then
			git checkout prod
			git branch -D master
		fi

	fi # end if ! repodir

done # end foreach $REPOS

# print runtime
TIME=$( expr $(date +%s) - $START )
echo "Finished in $TIME seconds at $( date +%F\ %T )"
