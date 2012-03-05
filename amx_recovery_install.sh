#!/bin/bash
#
# This script is designed to install the AdvantageMX images in Linux Ubuntu.
# And make it easier for people that want to develop for Android ROM using Linux Ubuntu.
# Script written by Vasencheg ( vasencheg@gmail.com )
# AMX Team ( http://advantagemx.ru )



# DEVICE SPECIFIC VARIABLES
# Acer Liquid Mini E310 VID and PID
DEVICE="Acer Liquid Mini E310"
DEVICE_VID="0502"
DEVICE_PID_ADB="3307"
DEVICE_PID_FASTBOOT="3306"

# OTHERS
UDEV_RULES_FILE="51-android.rules"

AMX_USER=$1
APP_DIR=$PWD

ADB="./adb"
FASTBOOT="./fastboot"

IMG="./recovery.img"
PARTITION="recovery"


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
        echo -e "Check udev rules..."
        echo
        if test -f $UDEV_RULES_FILE; then
                echo "The file $UDEV_RULES_FILE is already exist"
        else
                echo -n "Creating $UDEV_RULES_FILE file: "
                touch $UDEV_RULES_FILE
                echo "done"
        fi

        test_pattern_adb=`egrep "^.*$DEVICE_VID.*$DEVICE_PID_ADB.*$" $UDEV_RULES_FILE`
        if ! test -z "${test_pattern_adb}"; then
                echo "The ADB rules already exist: skipping."
        else
                echo -n "Creating rules for the ADB protocol: "
                echo "# $DEVICE. Rules for the adb protocol" >> $UDEV_RULES_FILE
                echo SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"$DEVICE_VID\", ATTR{idProduct}==\"$DEVICE_PID_ADB\", SYMLINK+=\"android_adb\", MODE=\"0600\", OWNER=\"USERNAME\" >> $UDEV_RULES_FILE
                echo "done"
        fi

        test_pattern_fastboot=`egrep "^.*$DEVICE_VID.*$DEVICE_PID_FASTBOOT.*$" $UDEV_RULES_FILE`
        if ! test -z "${test_pattern_fastboot}"; then
                echo "The Fast Boot rules already exist: skipping."
        else
                echo -n "Creating rules for the Fast Boot protocol: "
                echo "# $DEVICE. Rules for the fastboot protocol" >> $UDEV_RULES_FILE
                echo SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"$DEVICE_VID\", ATTR{idProduct}==\"$DEVICE_PID_FASTBOOT\", SYMLINK+=\"android_fastboot\", MODE=\"0600\", OWNER=\"USERNAME\" >> $UDEV_RULES_FILE
                echo "done"
        fi

        sed "s/USERNAME/$AMX_USER/g" $UDEV_RULES_FILE > tempfile1
        cat tempfile1 > $UDEV_RULES_FILE
        rm tempfile1
        chmod a+r $UDEV_RULES_FILE

        echo -n "Restarting UDEV:   "
        restart udev
        echo
        echo -n -e "Please, reattach the device and then press ${ltylw}ENTER${toff} to continue..."
        read

        cd  $APP_DIR
}

device_check() {
        echo -e -n "Searching for ${ltcyn} $DEVICE ${toff}: "
        while [ "`lsusb | grep -E "ID $DEVICE_VID"`" = "" ]
        do
	        echo -e "${ltred}device not found${toff}"
                echo
                echo -n -e "Please, plug the device to PC and press ${ltylw}ENTER${toff} ..."
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
        if ! test -f "$IMG"
        then
                echo "$IMG isn't found"
                echo "Exit."
                exit 1
        fi
        echo
        echo "Erasing the old $PWD$PARTITION..."
        "$FASTBOOT" -i 0x$DEVICE_VID erase $PARTITION
        echo
        echo "Try flashing..."
        "$FASTBOOT" -i 0x$DEVICE_VID flash $PARTITION "$IMG"
        echo
        echo -n -e "Press ${ltylw}ENTER${toff} to continue..."
        read
        "$FASTBOOT" -i 0x$DEVICE_VID reboot
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
    Welcome to AdvantageMX $PARTITION Installer

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
# check udev rules
stage 1
udev_rules_check
# check device
stage 2
device_check
stage 3
install
exit 0
