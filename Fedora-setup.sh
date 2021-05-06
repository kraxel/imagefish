#!/bin/sh

vers="${1-34}"
repo="repos/fedora-${vers}-$(sh basearch.sh).repo"

# figure what we are running on
eval $(grep ID= /etc/os-release)

if test ! -f "$repo" -a "$ID" = "fedora"; then
	echo "# no repo, using machine repos"
	for config in fedora fedora-updates; do
		file="/etc/yum.repos.d/${config}.repo"
		echo "#   << $file"
		sed	-e "s/^\[/[mkimage-/"			\
			-e "s/\$releasever/$vers/"		\
			-e "s/\$basearch/$(sh basearch.sh)/"	\
			< "$file" >> "$repo"
	done
	echo "#   >> $repo"
fi
