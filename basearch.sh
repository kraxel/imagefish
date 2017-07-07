#!/bin/sh
uname -m | sed				\
	-e 's/i?86/i386/'		\
	-e 's/armv7l.*/armv7hl/'
