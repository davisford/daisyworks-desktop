#! /bin/sh
#
# Shell script to copy the linux JRE to the air deploy dir
# This is called by the Ant build script.  The only reason
# this exists here is b/c Ant's built-in <copy> tasks do 
# not preserve permissions, so the JRE gets copied, but no
# executable bits are set, and if you run the installer and
# launch the app, java won't run.
#
PATH=/sbin:/bin:/usr/sbin:/usr/bin

JRE=jre1.6.0_25

# -K = keep setuid/setgid/tacky permissions
# -X = restore UID/GID info
# -o = overwrite no prompt
# -u = update, create if necessary
# -d = dir to unzip into

# clean out; use absolute paths please...easy to rm -rf the entire hard drive
rm -rf ./daisyworks-desktop-air/deploy/jre/*
rm -rf ./daisyworks-desktop-air/bin-debug/jre/*

# unzip JRE for packaging
unzip -K -X -o -u -d ./daisyworks-desktop-air/deploy/jre/ 	./jre/linux/jre1.6.0_25/jre1.6.0_25.zip

# unzip JRE to bin-debug so it can be used in dev
unzip -K -X -o -u -d ./daisyworks-desktop-air/bin-debug/jre/ 	./jre/linux/jre1.6.0_25/jre1.6.0_25.zip
