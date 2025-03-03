#!/bin/bash


usage () {
  echo "Usage: $(basename "$0") TAG"
  echo "Where:"
  echo "  TAG is osg-SERIES-DVER-REPO or devops-DVER-REPO"
  echo "  SERIES is: 3.1, 3.2, etc, or upcoming"
  echo "  DVER is: el5, el6, etc."
  echo "  REPO is: contrib, development, testing, or release for osg"
  echo "       or: itb or production for devops (formerly goc)"
  echo "  DESTDIR defaults to /etc/mash/"
  exit 1
}

[[ $# -eq 1 ]] || usage
TAG=$1

case $TAG in
  osg-*-*-* ) IFS='-' read osg SERIES DVER REPO <<< "$TAG" ;;
  devops-*-*| \
  goc-*-*   ) IFS='-' read SERIES DVER REPO <<< "$TAG" ;;
          * ) usage ;;
esac

release_path="/usr/local/repo/osg/$SERIES/$DVER/$REPO"
working_path="/usr/local/repo.working/osg/$SERIES/$DVER/$REPO"
previous_path="/usr/local/repo.previous/osg/$SERIES/$DVER/$REPO"
reponame=$TAG

mkdir -p "$release_path" "$working_path" "$previous_path"
mash "$reponame" -o "$working_path" -p "$release_path"
if [ "$?" -ne "0" ]; then
        echo "mash failed - please see error log" >&2
        exit 1
fi

rm -rf "$previous_path"
mv "$release_path" "$previous_path"
mv "$working_path/$reponame" "$release_path"

if [[ $REPO = release && $SERIES != upcoming ]]; then
        echo "creating osg-$SERIES-$DVER-release-latest symlink"
        cd /usr/local/repo/osg/"$SERIES"
        # use ls version-sort so that 3.2-11 > 3.2-2
        target=$(ls -v "$DVER/$REPO"/x86_64/osg-release-[1-9]*.rpm | tail -1)
        echo "target: $target"
        if [[ $target ]]; then
                ln -fs "$target" "osg-$SERIES-$DVER-release-latest.rpm"
        else
                echo "didn't find the osg-release rpm under $SERIES/$DVER/$REPO"
        fi
fi

