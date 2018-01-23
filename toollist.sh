#/bin/bash
#
# list tools in repo

BASEDIR="/home/vagrant/repoconv"
REPO="test"
REPOBASE="svn+ssh://atgsvn.itc.virginia.edu/$REPO/uva-collab"
AUTHORS="$BASEDIR/authors/combined.txt"

TOOLS=$( svn ls $REPOBASE )

CMD="git svn clone $REPOBASE --no-metadata -A $AUTHORS"

for t in $TOOLS; do

	tool="$( echo $t | tr -d "/" )"

	CMD="${CMD} -b\"$tool/branches\" -b\"$tool/vendor\" -t\"$tool/tags\""

done

CMD="${CMD} $BASEDIR/repos/$REPO"

$CMD
