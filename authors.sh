#/bin/bash
#
# extract authors from svn repo

REPO_ROOT="svn+ssh://atgsvn.itc.virginia.edu"

REPO=$1

svn log -q $REPO_ROOT/$REPO | awk -F '|' '/^r/ {sub("^ ", "", $2); sub(" $", "", $2); print $2" = "$2" <"$2">"}' | sort -u
