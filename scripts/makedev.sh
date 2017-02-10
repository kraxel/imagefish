#!/bin/sh

dest="$1"

if test "$dest" = ""; then
	echo "usage: $0 <destdir>"
	exit 1
fi
if test ! -d "$dest"; then
	echo "$dest: no such directory"
	exit 1
fi

mknod	$dest/null	c 1 3
mknod	$dest/zero	c 1 5
mknod	$dest/full	c 1 7
mknod	$dest/random	c 1 8
mknod	$dest/urandom	c 1 9

mknod	$dest/tty	c 5 0
mknod	$dest/console	c 5 1
