
@echo off
﻿set BASEDIR=%CD%
set IWNNSERVER_DIR=iwnnserver
set DIC_DEVICE_PATH=/system/bin/dic

echo Remount file systems of Flame
echo "### Waiting for device... please ensure it is connected, switched on and remote debugging is enabled in Gaia"
adb wait-for-device
echo "### Restarting adb with root permissions..."
adb root
adb wait-for-device
echo "### Remounting the /system partition..."
adb remount
adb shell mount -o remount,rw /system
echo "### Stopping b2g process..."
adb shell stop b2g

echo Install iWnn Server
adb push %IWNNSERVER_DIR%/iWnnServer /system/bin/iWnnServer
adb shell chown 1059:3004 /system/bin/iWnnServer
adb shell chmod 6777 /system/bin/iWnnServer

echo Setup direcotories for iWnn Server
adb shell mkdir -p /data/iwnn
adb shell mkdir -p /data/iwnn/rewrite
adb shell chown 1059:3004 /data/iwnn
adb shell chown 1059:3004 /data/iwnn/rewrite
adb shell chown 1059:3004 /data/iwnn/rewrite/*
adb shell chmod 0770 /data/iwnn
adb shell chmod 0770 /data/iwnn/rewrite

echo Install files for iWnn Server
adb shell mkdir -p %DIC_DEVICE_PATH%
adb push %IWNNSERVER_DIR%/serv_info.txt %DIC_DEVICE_PATH%/serv_info.txt
adb push %IWNNSERVER_DIR%/dic/njcon.dic %DIC_DEVICE_PATH%/njcon.dic
adb push %IWNNSERVER_DIR%/dic/njfzk.dic %DIC_DEVICE_PATH%/njfzk.dic
adb push %IWNNSERVER_DIR%/dic/njtan.dic %DIC_DEVICE_PATH%/njtan.dic
adb push %IWNNSERVER_DIR%/dic/njubase1.dic %DIC_DEVICE_PATH%/njubase1.dic
adb push %IWNNSERVER_DIR%/dic/njubase2.dic %DIC_DEVICE_PATH%/njubase2.dic
adb push %IWNNSERVER_DIR%/dic/njaddress.dic %DIC_DEVICE_PATH%/njaddress.dic
adb push %IWNNSERVER_DIR%/dic/njadd.dic %DIC_DEVICE_PATH%/njadd.dic
adb push %IWNNSERVER_DIR%/dic/njkaomoji.dic %DIC_DEVICE_PATH%/njkaomoji.dic
adb push %IWNNSERVER_DIR%/dic/njname.dic %DIC_DEVICE_PATH%/njname.dic
adb push %IWNNSERVER_DIR%/dic/njemoji.dic %DIC_DEVICE_PATH%/njemoji.dic
adb push %IWNNSERVER_DIR%/dic/njexyomi.dic %DIC_DEVICE_PATH%/njexyomi.dic
adb push %IWNNSERVER_DIR%/dic/njemailuri.dic %DIC_DEVICE_PATH%/njemailuri.dic
adb push %IWNNSERVER_DIR%/dic/njexyomi_plus.dic %DIC_DEVICE_PATH%/njexyomi_plus.dic

echo Update b2g.sh
mkdir temp
adb pull /system/bin/b2g.sh temp/b2g.sh
find "iWnn" temp\b2g.sh
if not errorlevel 1 (
  echo "already have iWnn entry in b2g.sh"
) else (
  sed -i "1a\/system/bin/iWnnServer /data/iwnn &" "temp/b2g.sh"
  adb push temp/b2g.sh /system/bin/b2g.sh
  adb shell chmod 755 /system/bin/b2g.sh
)
rmdir /Q /S temp

echo iWnn Server Installation Completed.
echo Please install keyboard-iwnn app via App Manager.
echo Rebooting the Device...

adb shell sync
adb shell reboot
adb wait-for-device
