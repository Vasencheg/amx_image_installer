#!/bin/bash
#
# This script is designed to install the AdvantageMX CWM-based recovery in Linux Ubuntu.
# And make it easier for people that want to develop for Android ROM using Linux Ubuntu.
# Script written by Vasencheg ( vasencheg@gmail.com )
# AMX Team ( http://advantagemx.ru )


# Acer Liquid Mini E310 VID and PID
DEVICE="Acer Liquid Mini E310"
DEVICE_VID="0x0502"
DEVICE_PID_ADB="0x3307"
DEVICE_PID_FASTBOOT="0x3306"

UDEV_RULES_FILE="52-android_acer_e310.rules"

AMX_USER=$1

APP_DIR=$PWD
FASTBOOT="./fastboot"
RECOVERY_IMG="./recovery.img"


colors_export() {
        export toff="\e[0m"  # Color off
        export tblk="\e[0;30m" # Black
        export tred="\e[0;31m" # Red
        export tgrn="\e[0;32m" # Green
        export tylw="\e[0;33m" # Yellow
        export tblu="\e[0;34m" # Blue
        export tprpl="\e[0;35m" # Purple
        export tcyn="\e[0;36m" # Cyan
        export ltblk="\e[1;30m" # Black
        export ltred="\e[1;31m" # Red
        export ltgrn="\e[1;32m" # Green
        export ltylw="\e[1;33m" # Yellow
        export ltblu="\e[1;34m" # Blue
        export ltprpl="\e[1;35m" # Purple
        export ltcyn="\e[1;36m" # Cyan
}

udev_rules_check() {
        cd /etc/udev/rules.d
        echo -e "Check USB rule for device..."
        echo
        if test -f $UDEV_RULES_FILE; then
                echo "The file $UDEV_RULES_FILE is already exist"
        else
                echo -n "Creating $UDEV_RULES_FILE file: "
                touch $UDEV_RULES_FILE
                echo "# rules for $DEVICE" >> $UDEV_RULES_FILE
                echo SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"$DEVICE_VID\", SYMLINK+=\"android_adb\", MODE=\"0666\", OWNER=\"USERNAME\" >> $UDEV_RULES_FILE
                sed "s/USERNAME/$AMX_USER/g" $UDEV_RULES_FILE > tempfile1
                cat tempfile1 > $UDEV_RULES_FILE
                rm tempfile1
                chmod a+r $UDEV_RULES_FILE
                echo "done"
                echo -n "Restarting UDEV:   "
                restart udev
        fi
        cd  $APP_DIR
}

device_check() {
        echo -e "Searching for ${ltcyn} $DEVICE ${toff}..."
        while [ "`lsusb | grep -E "ID 0502"`" = "" ]
        do
	        echo -n -e "  ${ltred}Device not found${toff}. Please, plug the device to PC and press ${ltylw}ENTER${toff} ..."
                read
        done
        echo "done"
}

cmd_excute() {
        (($1 2>&1 1>&3 | tee /dev/stderr ; exit ${PIPESTATUS[0]}) 3>&1) > logfile
}

install() {
        echo "Starting installation..."
        if ! test -f "$FASTBOOT"
        then
                echo "Android fastboot tool isn't found"
                echo "Exit."
                exit 1
        fi
        if ! test -f "$RECOVERY_IMG"
        then
                echo "recovery.img isn't found"
                echo "Exit."
                exit 1
        fi
        echo
        echo "Erasing the old recovery..."
        "$FASTBOOT" -i 0x0502 erase recovery
        echo
        echo "Try flashing..."
        "$FASTBOOT" -i 0x0502 flash recovery "$RECOVERY_IMG"
        echo
        echo -n -e "Press ${ltylw}ENTER${toff} to continue..."
        read
        "$FASTBOOT" -i 0x0502 reboot
}

stage() {
        echo
        echo -e "${ltgrn}--------------Stage $1 --------------${toff}: "
}


# run script from root
if [ "`id -u`" != "0" ]; then
        if [ -z $AMX_USER ]; then
                AMX_USER=`id -un`
                echo $AMX_USER
        fi
        echo "This script require the root priveleges:"
        sudo bash "$0" "$AMX_USER"
        exit "$?";
fi;
clear
colors_export
echo -e "${ltgrn}
--------------------------------------------------
    Welcome to AdvantageMX recovery Installer

              -= AMX Team =-
          http://advantagemx.ru

        Script written by Vasencheg
            vasencheg@gmail.com
--------------------------------------------------
${toff}
${ltylw}You are about to install:
  - AdvantageMX is a ClockWork Mod based Recovery
    for Acer Liquid Mini E310

Be sure you have checked this points :
  - your phone is in FASTBOOT mode

If you meet these requirements, you can go ${toff}

"
echo -n -e "Press ${ltylw}ENTER${toff} to continue..."
read
echo
echo
# check device
stage 1
device_check
# check udev rules
stage 2
udev_rules_check
stage 3
install
exit 0
