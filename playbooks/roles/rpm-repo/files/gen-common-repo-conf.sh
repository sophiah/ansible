#!/bin/sh

repodir_root=$1
prefix=$2
files=`find $repodir_root -type d -links 2`
hostname=`hostname -I | head -1`
hostname=`echo $hostname | sed 's/^ *//' | sed 's/ *$//'`

for f in $files ; do
    name=`echo $f | perl -ne '{ @v = split("/", $_); $ln = $#v -1; print join "_", @v[3..$ln];  }'`
    dir=`echo $f | perl -ne '{ @v = split("/", $_); $ln = $#v -1; print join "/", @v[3..$ln];  }'`
    echo "
[$prefix_$name]
name=$name
baseurl=http://${hostname}/${dir}
failovermethod=priority
enabled=1
gpgcheck=0

    " > /etc/yum.repos.d/$prefix.$name.conf

    cp /etc/yum.repos.d/$prefix.$name.conf $repodir_root
done


