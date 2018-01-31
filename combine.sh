#!/bin/bash
#
# combine disparate tool repos into one big archival repo (for prev versions of sakai)

START=$( date +%s )

#VERSIONS="2-5-x 2-6-x 2-7-x 2-8-x 2-9-x 10-x"
VERSIONS="2-5-x"
STATES="dev test preprod prod"

BASE="/home/vagrant/repoconv"
TOOLS="$BASE/work/tools"
IGNORE="$BASE/work/ignore"
WORK="$BASE/work/combined"
SVNROOT="svn+ssh://atgsvn.itc.virginia.edu/sakai"

for VERSION in $VERSIONS; do

	repo=$( echo $VERSION | sed "s/-/./g" )

	# create empty repo
	if [[ ! -d "$WORK/$repo" ]]; then
		mkdir "$WORK/$repo"
		cd "$WORK/$repo"
		git init
		git commit --allow-empty -m "initializing $repo repository"

		# create branch for each prodstatus
		for STATE in $STATES; do

			echo ">"
			echo "> $VERSION/$STATE"
			echo ">"

			git checkout master
			git checkout -b $STATE

			if [[ -f .gitignore ]]; then
				rm .gitignore
			fi

			branch="sakai_${VERSION}_${STATE}"

			# loop through tool dirs, importing
			for tool in $( ls $TOOLS ); do

				if [[ $( cd $TOOLS/$tool; git branch | grep "$branch") ]]; then

					echo ">>"
					echo ">> $VERSION / $STATE / $tool"
					echo ">>"

					git remote add -t "$branch" $tool $TOOLS/$tool
					#git fetch $tool
					#git merge -m "$repo/$STATE: importing $tool" --commit "$tool/$branch"
					git pull --rebase $tool
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

				# export and commit top-level build pom
				svn export $SVNROOT/uva-collab-build/branches/$branch/pom.xml pom.xml
				git add pom.xml
				commitmsg="importing top-level build pom"

				# add ignores
				if [[ -f .gitignore ]]; then
					git add .gitignore
					commitmsg="$commitmsg and converted svn:ignore props"
				fi

				git commit -m "$commitmsg"

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
FINISH=$( date +%s )
TIME=$( expr $FINISH - $START )
echo "Finished in $TIME seconds"
