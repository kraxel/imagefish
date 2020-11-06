#!/bin/sh
wget	--recursive		\
	--accept "*.xz"		\
	--span-hosts		\
	--no-directories	\
	--continue		\
	https://kraxel.gitlab.io/imagefish/
