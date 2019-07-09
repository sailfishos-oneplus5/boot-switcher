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
[[ -f /system/build.prop && -f /vendor/etc/init/hw/init.qcom.rc ]] || abort 4 "Please install LineageOS before flashing this zip."

# TODO: Fix showing below message even after above abort?
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
	SFOS_REL=`cat /data/.stowaways/sailfishos/etc/os-release | grep VERSION= | cut -d'=' -f2 | cut -d'"' -f2` # e.g. '3.0.3.10 (Hossa)'
	TARGET_PRETTY="SailfishOS $SFOS_REL" # e.g. "SailfishOS 3.0.3.10 (Hossa)"
else                           # LineageOS
	touch "$TARGET_FILE"

	DROID_VER=`cat /system/build.prop | grep ro.build.version.release | cut -d'=' -f2 | cut -d'.' -f1` # e.g. "8"
	DROID_REL="" # e.g. "Oreo"

	if [ "$DROID_VER" = "9" ]; then
		DROID_REL="Pie"
	elif [ "$DROID_VER" = "8" ]; then
		DROID_REL="Oreo"
	elif [ "$DROID_VER" = "7" ]; then
		DROID_REL="Nougat"
	elif [ "$DROID_VER" = "6" ]; then
		DROID_REL="Marshmellow"
	elif [ "$DROID_VER" = "5" ]; then
		DROID_REL="Lollipop"
	elif [ "$DROID_VER" = "4" ]; then
		DROID_REL="KitKat"
	fi

	[ ! -z $DROID_REL ] && DROID_REL=" ($DROID_REL)" # e.g. " (Oreo)"

	LOS_VER=`cat /system/build.prop | grep ro.lineage.build.version= | cut -d'=' -f'2'` # e.g. "15.1"
	TARGET_PRETTY="Android $DROID_VER$DROID_REL" # e.g. "Android 7.1.1 (Nougat)"
	[ ! -z $LOS_VER ] && TARGET_PRETTY="LineageOS $LOS_VER$DROID_REL" || TARGET_DROID_LOS="0" # e.g. "LineageOS 15.1 (Oreo)"
fi

# Calculate centering offset indent on left
target_len=`echo -n $TARGET_PRETTY | wc -m` # e.g. 21 for "LineageOS 15.1 (Oreo)"
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

	ui_print "                         NKOdc'lX"
	ui_print "                      NOdoddxllX"
	ui_print "                    Xd:ckNWWkl0"
	ui_print "                  Xx,.lX   NllX            WX0"
	ui_print "                WOl:,oN N0ko:codOXNWWNK0kxdddx"
	ui_print "               WkckxcOKxddxOXWNOoc;;clodxOKNW"
	ui_print "               OckWO::okX   N0xddddk0NW"
	ui_print "              WdlX Wk:oNW0xdodkKN"
	ui_print "              WxlK  WKdl:cokX"
	ui_print "               Xdo0W  WKdllkN"
	ui_print "                WOodKW  W0xldN"
	ui_print "                  No,oX    k:O"
	ui_print "                   O;;oK WNdcK"
	ui_print "                  WdlOodNklckW"
	ui_print "                 WkcO0cloloOW"
	ui_print "                Xdlkk;.ckX"
	ui_print "             WXxllol:lkN"
	ui_print "          WXkc''codON"
	ui_print "      NKkdl::cdOXW"
	ui_print "      c;;lx0N"
else
	ln -sf /tmp/lineage-boot.img /tmp/boot.img

	if [ "$TARGET_DROID_LOS" = "1" ]; then
		ui_print " "
		ui_print " "
		ui_print " "
		ui_print " "
		ui_print "                   N0xl::;;;:lx0N"
		ui_print "                 N0dc:coddddol:cdON"
		ui_print "               WXd:cd0XWWWWWWN0xc:oKW"
		ui_print "               Xo:o0W WX0OO0XW WKo:oK"
		ui_print "              Wk:c0W Nkc:;;:cxX  Kl:xN"
		ui_print " WX0OkOKWWNX0Oxl;oX  0c;;;;;;cO  Nd;cxO0XNWWX0OO0XW"
		ui_print "Kdccllccodlcllol:l0  Nx:;;;;:dX  Ko:oolccldoccllccxX"
		ui_print "o:oKNNKo;cx0XNWKo:oKW WKOkkOKNWWXdcdXWNX0d:;o0NNKd:x"
		ui_print "l:dN  Nx:oX    WKd:lkKNW    WNKkllkN     0l;dXWWNx:d"
		ui_print "Olcoxxoco0W      N0dlcodxxxxdoloxKW      NOl:lxxocoK"
		ui_print " Kdc::cxKW         WKkoc:::cldOXW         W0dc::lkX"
		ui_print " "
		ui_print " "
		ui_print " "
		ui_print " "
		ui_print " "
	else
		ui_print "                  WNW          WNW"
		ui_print "                 WKk0NWNNNNNNWN0kKW"
		ui_print "                 WXkdkkxxxxxxkxdkXW"
		ui_print "                N0kdxkxddddddxkxdk0N"
		ui_print "               XOdddO0kddddddk0OdddOX"
		ui_print "              W0xxxxxxxxxxxxxxxxxxxx0W"
		ui_print "          WW  WNXXXXXXXXXXXXXXXXXXXXNW  WW"
		ui_print "        WKkOKWN0kkkkkkkkkkkkkkkkkkkk0NWKOOKN"
		ui_print "        XkddkXNOddddddddddddddddddddkNNkddkX"
		ui_print "        XkddkXNOddddddddddddddddddddONXkddkX"
		ui_print "        XkddkXNOddddddddddddddddddddONXkddkX"
		ui_print "        XkddkNNOddddddddddddddddddddONXkddxX"
		ui_print "        XkddkNNOddddddddddddddddddddONNkddkX"
		ui_print "        WKkOKWNkddddddddddddddddddddkNWKOOKW"
		ui_print "          WW  NOddddddddddddddddddddON  WW"
		ui_print "              WKkkxxdddxxkkxxdddxxkkKW"
		ui_print "                WNXOddx0NNNN0xddOXNWW"
		ui_print "                  WOddxKW  WKxddON"
		ui_print "                  W0ddxK   WKxdd0W"
		ui_print "                  WNK0KW    WK0KN"
	fi
fi
ui_print " "
ui_print "${indent}Switching boot target to $TARGET_PRETTY"
ui_print "                   Please wait ..."

log "New boot target: '$TARGET_PRETTY'"

log "Patching /vendor init files..."
if [ $TARGET = "droid" ]; then
	(sed -i "s/service qti.*/service qti \/vendor\/bin\/qti/" /vendor/etc/init/hw/init.qcom.rc && sed -i "s/service time_daemon.*/service time_daemon \/vendor\/bin\/time_daemon/" /vendor/etc/init/hw/init.qcom.rc) || abort 7 "Failed to patch init files in /vendor."
else
	(sed -i "s/service qti.*/service qti \/vendor\/bin\/qti_HYBRIS_DISABLED/" /vendor/etc/init/hw/init.qcom.rc && sed -i "s/service time_daemon.*/service time_daemon \/vendor\/bin\/time_daemon_HYBRIS_DISABLED/" /vendor/etc/init/hw/init.qcom.rc) || abort 7 "Failed to patch init files in /vendor."
fi

log "Writing new boot image..."
#show_progress 1 4
dd if=/tmp/boot.img of=/dev/block/sde19 || abort 8 "Writing new boot image failed."

log "Cleaning up..."
umount /vendor &> /dev/null
umount /system &> /dev/null

# <<< Script end <<<

# Succeeded.
log "Boot target updated successfully."
ui_print "            All done, enjoy your new OS!"
ui_print " "
exit 0
