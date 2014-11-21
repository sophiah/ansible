#!/bin/sh

files=`find {{ repodir_root }} -type d -links 2`

for f in $files ; do
    dir=`dirname $f`
    /usr/bin/createrepo --update -v $dir
done

chconAttr=`ls -la --context /var/www/html | head -1 | awk '{ print $4}'`
chcon -R ${chconAttr} {{ repodir_root }}

