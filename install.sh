#!/bin/bash

IWNNSERVER_DIR=iwnnserver
DIC_DEVICE_PATH=/system/bin/dic

## adb with flags
function run_adb() {
    $(pwd)/adb $ADB_FLAGS $@
}

function check_adb_result() {
    RET=$1
    if [[ $RET == *"error"* ]]; then
        check_exit_code 1 "Please make sure adb is running as root."
    elif [[ $RET == *"cannot run as root"* ]]; then
        check_exit_code 1 "Please make sure adb is running as root."
    elif [[ $RET == *"remount failed"* ]]; then
        check_exit_code 1 "Please make sure adb is running as root."
    elif [[ $RET == *"Operation not permitted"* ]]; then
        check_exit_code 1 "Please make sure adb is running as root."
    fi
}

## adb root, then remount and stop b2g
function adb_root_remount() {
    echo "### Waiting for device... please ensure it is connected, switched on and remote debugging is enabled in Gaia"
    run_adb wait-for-device

    echo "### Restarting adb with root permissions..."
    RET=$(run_adb root)
    echo "$RET"
    check_adb_result "$RET"
    run_adb wait-for-device

    echo "### Remounting the /system partition..."
    RET=$(run_adb remount)
    echo "$RET"
    check_adb_result "$RET"
    RET=$(run_adb shell mount -o remount,rw /system)
    echo "$RET"
    check_adb_result "$RET"

    echo "### Stopping b2g process..."
    run_adb shell stop b2g
}

## adb sync then reboot
function adb_reboot() {
    run_adb shell sync
    run_adb shell reboot
    run_adb wait-for-device
}

echo Remount file systems of Flame
adb_root_remount

echo Install iWnn Server
run_adb push $IWNNSERVER_DIR/iWnnServer /system/bin/iWnnServer
run_adb shell chown 1059:3004 /system/bin/iWnnServer
run_adb shell chmod 6777 /system/bin/iWnnServer

echo Setup direcotories for iWnn Server
run_adb shell mkdir -p /data/iwnn
run_adb shell mkdir -p /data/iwnn/rewrite
run_adb shell chown 1059:3004 /data/iwnn
run_adb shell chown 1059:3004 /data/iwnn/rewrite
run_adb shell chown 1059:3004 /data/iwnn/rewrite/*
run_adb shell chmod 0770 /data/iwnn
run_adb shell chmod 0770 /data/iwnn/rewrite

echo Install files for iWnn Server
run_adb shell mkdir -p $DIC_DEVICE_PATH
run_adb push $IWNNSERVER_DIR/serv_info.txt $DIC_DEVICE_PATH/serv_info.txt
run_adb push $IWNNSERVER_DIR/dic/njcon.dic $DIC_DEVICE_PATH/njcon.dic
run_adb push $IWNNSERVER_DIR/dic/njfzk.dic $DIC_DEVICE_PATH/njfzk.dic
run_adb push $IWNNSERVER_DIR/dic/njtan.dic $DIC_DEVICE_PATH/njtan.dic
run_adb push $IWNNSERVER_DIR/dic/njubase1.dic $DIC_DEVICE_PATH/njubase1.dic
run_adb push $IWNNSERVER_DIR/dic/njubase2.dic $DIC_DEVICE_PATH/njubase2.dic
run_adb push $IWNNSERVER_DIR/dic/njaddress.dic $DIC_DEVICE_PATH/njaddress.dic
run_adb push $IWNNSERVER_DIR/dic/njadd.dic $DIC_DEVICE_PATH/njadd.dic
run_adb push $IWNNSERVER_DIR/dic/njkaomoji.dic $DIC_DEVICE_PATH/njkaomoji.dic
run_adb push $IWNNSERVER_DIR/dic/njname.dic $DIC_DEVICE_PATH/njname.dic
run_adb push $IWNNSERVER_DIR/dic/njemoji.dic $DIC_DEVICE_PATH/njemoji.dic
run_adb push $IWNNSERVER_DIR/dic/njexyomi.dic $DIC_DEVICE_PATH/njexyomi.dic
run_adb push $IWNNSERVER_DIR/dic/njemailuri.dic $DIC_DEVICE_PATH/njemailuri.dic
run_adb push $IWNNSERVER_DIR/dic/njexyomi_plus.dic $DIC_DEVICE_PATH/njexyomi_plus.dic

echo Update b2g.sh
mkdir -p temp
run_adb pull /system/bin/b2g.sh temp/b2g.sh
if [ -n "`grep \"iWnn\" temp/b2g.sh`" ]; then
  echo "already have iWnn entry in b2g.sh"
else
  if [ "$(uname)" == "Darwin" ]; then
    # for FreeBSD-sed (Mac OS X):
    sed -i '' '2s|^|/system/bin/iWnnServer /data/iwnn \&\
    |' "temp/b2g.sh"
  else
    # for Gnu-sed (Linux):
    sed -i '2s|^|/system/bin/iWnnServer /data/iwnn \&\n|' "temp/b2g.sh"
  fi
  run_adb push temp/b2g.sh /system/bin/b2g.sh
  run_adb shell chmod 755 /system/bin/b2g.sh
fi
rm -R temp

echo iWnn Server Installation Completed.
echo Please install keyboard-iwnn app via App Manager.
echo Rebooting the Device...

adb_reboot
