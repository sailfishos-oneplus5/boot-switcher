#! /sbin/sh
# This is a script to switch boot target between Android and Sailfish OS when executed.

# >>> Get TWRP output pipe fd >>>

OUTFD=0

# we are probably running in embedded mode, see if we can find the right fd
# we know the fd is a pipe and that the parent updater may have been started as
# 'update-binary 3 fd zipfile'
for FD in `ls /proc/$$/fd`; do
	readlink /proc/$$/fd/$FD 2>/dev/null | grep pipe >/dev/null
	if [ "$?" -eq "0" ]; then
		ps | grep " 3 $FD " | grep -v grep >/dev/null
		if [ "$?" -eq "0" ]; then
			OUTFD=$FD
			break
		fi
	fi
done

# <<< Get TWRP output pipe fd <<<

# >>> Implement TWRP functions >>>

ui_print() {
	echo -en "ui_print $1\n" >> /proc/self/fd/$OUTFD
	echo -en "ui_print\n" >> /proc/self/fd/$OUTFD
}

# TODO: Implement show_progress function

# <<< Implement TWRP functions <<<

# >>> Custom functions >>>

# TODO Write to stderr if TWRP output in RED

# Write error message & exit.
# args: 1=errcode, 2=msg
abort() {
	ui_print "$2"
	exit $1
}

log() {
	echo "switch-boot-target: $@"
}

# <<< Custom functions <<<

# >>> Sanity checks >>>

# Treble
if [ ! -r /dev/block/bootdevice/by-name/vendor ]; then
	abort 1 "Vendor partition doesn't exist; you need to do an OTA from OxygenOS 5.1.5 to 5.1.6!"
fi

# Android
umount /system &> /dev/null
mount /system || abort 2 "Couldn't mount /system!"
umount /vendor &> /dev/null
mount -o rw /vendor || abort 3 "Couldn't mount /vendor!"
[[ "$(cat /system/build.prop | grep lineage.build.version= | cut -d'=' -f2)" = "15.1" && -f /vendor/etc/init/hw/init.qcom.rc ]] || abort 4 "Please factory reset & dirty flash LineageOS 15.1 before this zip."
log "Android OS installation detected"

# Sailfish OS
umount /data &> /dev/null
mount /data || abort 5 "Couldn't mount /data; running e2fsck and rebooting may help"
[ -f /data/.stowaways/sailfishos/etc/os-release ] || abort 6 "Please install Sailfish OS before flashing this zip."

log "Sailfish OS installation detected"
log "Passed sanity checks (2/2)"

# <<< Sanity checks <<<

# >>> Script start >>>

# Boot target to switch to
TARGET="droid"
TARGET_DROID_LOS="1"
TARGET_PRETTY=""
TARGET_FILE="/data/.stowaways/droid_boot_target"
if [ -f "$TARGET_FILE" ]; then # Sailfish OS
	rm "$TARGET_FILE"

	TARGET="sfos"
	SFOS_REL=`cat /data/.stowaways/sailfishos/etc/os-release | grep VERSION_ID= | cut -d'=' -f2 | cut -d'"' -f2` # e.g. '3.0.3.10'
	TARGET_PRETTY="Sailfish OS $SFOS_REL" # e.g. "Sailfish OS 3.0.3.10"
else                           # LineageOS
	touch "$TARGET_FILE"

	DROID_VER=`cat /system/build.prop | grep ro.build.version.release | cut -d'=' -f2 | sed -r 's/^.0+|.0+$//g'` # e.g. "8.1"

	LOS_VER=`cat /system/build.prop | grep ro.lineage.build.version= | cut -d'=' -f2` # e.g. "15.1"
	TARGET_PRETTY="Android $DROID_VER" # e.g. "Android 7.1.1"
	[ ! -z $LOS_VER ] && TARGET_PRETTY="LineageOS $LOS_VER ($DROID_VER)" || TARGET_DROID_LOS="0" # e.g. "LineageOS 15.1 (8.1)"
fi

# Calculate centering offset indent on left
target_len=`echo -n $TARGET_PRETTY | wc -m` # e.g. 21 for "LineageOS 15.1 (8.1)"
start=`expr 52 - 25 - $target_len` # e.g. 7 
start=`expr $start / 2` # e.g. 3
log "indent offset is $start for '$TARGET_PRETTY'"

indent=""
for i in `seq 1 $start`; do
	indent="${indent} "
done

# Splash
ui_print " "
ui_print "-=============- Boot Target Switcher -=============-"
ui_print " "
if [ "$TARGET" = "sfos" ]; then
	ln -sf /tmp/hybris-boot.img /tmp/boot.img 

	ui_print "                          .':oOl."
	ui_print "                       ':c::;ol."
	ui_print "                    .:do,   ,l."
	ui_print "                  .;k0l.   .ll.             .."
	ui_print "                 'ldkc   .,cdoc:'.    ..,;:::;"
	ui_print "                ,o,;o'.;::;'.  'coxxolc:;'."
	ui_print "               'o, 'ddc,.    .;::::,."
	ui_print "               cl   ,x:  .;:c:,."
	ui_print "               ;l.   .:ldoc,."
	ui_print "               .:c.    .:ll,"
	ui_print "                 'c;.    .;l:"
	ui_print "                   :xc.    ,o'"
	ui_print "                   'xxc.   ;o."
	ui_print "                   :l'c: ,lo,"
	ui_print "                  ,o'.ooclc'"
	ui_print "                .:l,,x0o;."
	ui_print "              .;llcldl,"
	ui_print "           .,oOOoc:'"
	ui_print "       .,:lddo:'."
	ui_print "      oxxo;."
else
	ln -sf /tmp/droid-boot.img /tmp/boot.img

	if [ "$TARGET_DROID_LOS" = "1" ]; then
		ui_print " "
		ui_print " "
		ui_print " "
		ui_print " "
		ui_print "                         __"
		ui_print "                      :clllcc:"
		ui_print "                   :okOOOOOOOOko:"
		ui_print "                 :o0K:   __   :00o:"
		ui_print "                :dK0l :lxxxxo: l0Kd:"
		ui_print "        _       c0Ko :xNMMMMNx: oK0c       _"
		ui_print "     lxOOOkoldxk0N0l c0WMMMMM0c l0N0kxdlokOOOxl"
		ui_print "    oK0dodOXX0kddOXx: lOKXXKOl :xX0dxk0XXOdod0Ko"
		ui_print "   :kXx   lK0l   cOKkl:      :lkKOc   c0Ko   xXk:"
		ui_print "    l0Kkxx0Kd:    :dO0OkxddxkO0Od:    :dK0xxkK0l"
		ui_print "     coxkkdl        :ldxkkkkxdl:        ldkkxoc"
		ui_print " "
		ui_print " "
		ui_print " "
		ui_print " "
		ui_print " "
	else
		ui_print "                  .od.        .do."
		ui_print "                   'kOolllllloOk'"
		ui_print "                 .cdl:'.    .':ldc."
		ui_print "                ;xl''          ''lx;"
		ui_print "               ;k:   ::      ::   :k;"
		ui_print "              .xx..................xx."
		ui_print "              .okddddddddddddddddddko."
		ui_print "         .loo:,dxolllllllllllllllloxo,:ool."
		ui_print "         ox.:kxkl                  lkxk:.xo"
		ui_print "         dd.  xkc                  ckx  .dd"
		ui_print "         od.  xkc                  ckx  .do"
		ui_print "         od.  xkc                  ckx  .do"
		ui_print "         od.  xkc                  ckx  .do"
		ui_print "         ckc,kokc                  ckok,ckc"
		ui_print "          ,c:.'kl                  lk'.:c,"
		ui_print "               :dlcc.  .cccc.  .ccld:"
		ui_print "                .'cOo  oOooOo  oOc'."
		ui_print "                  .xo  ox,,xo  ox."
		ui_print "                  .dx''xo..ox''xd."
		ui_print "                   ,k00k,  ,k00k,"
	fi
fi
ui_print " "
ui_print "${indent}Switching boot target to $TARGET_PRETTY"
ui_print "                   Please wait ..."

log "New boot target: '$TARGET_PRETTY'"

log "Patching /vendor init files..."
if [ $TARGET = "droid" ]; then
	sed -e "s/cpuset.cpus/cpus/g" -e "s/cpuset.mems/mems/g" -i /vendor/etc/init/hw/init.target.performance.rc || abort 7 "Failed to patch init files in /vendor."
else
	sed -e "s/cpus 0/cpuset.cpus 0/g" -e "s/mems 0/cpuset.mems 0/g" -i /vendor/etc/init/hw/init.target.performance.rc || abort 7 "Failed to patch init files in /vendor."
fi

log "Writing new boot image..."
dd if=/tmp/boot.img of=/dev/block/bootdevice/by-name/boot || abort 8 "Writing new boot image failed."

log "Cleaning up..."
umount /vendor &> /dev/null
umount /system &> /dev/null

# <<< Script end <<<

# Succeeded.
log "Boot target updated successfully."
ui_print "            All done, enjoy your new OS!"
ui_print " "
exit 0