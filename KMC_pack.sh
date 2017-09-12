#! /bin/sh
set -e
if [ $# -lt 1 ]; then
echo "usage: $0 target"
echo "example: $0 KSYLiveDemo"
exit
fi

TARGET=$1
TARGET_DIR=`pwd`
USER_KEY="28efdc88bd23d0098f547e9325027cb5"
API_KEY="f8cb537bb80fbb4cd1395a010e8fa57c"

if [ ! -d $TARGET_DIR ]; then
echo "target dir doesn't exist, dir:$TARGET_DIR"
exit
fi

alias sed='sed -i "" -E '
echo "=================== prepare demo @ `date`==================="
cd $TARGET_DIR/demo
pod install
PROJECT_PARA="-workspace *.xcwork*"

echo "=================== archive demo @ `date`==================="
sed "s@(CODE_SIGN_ID.*iPhone) Developer@\1 Distribution@" \
${TARGET}.xcodeproj/project.pbxproj
sed "s@(PROVISIONING_PROFILE)(.*);@\1 = \"0306bb3a-2b76-4fd5-be69-a2eb11e7b7ca\";@" \
${TARGET}.xcodeproj/project.pbxproj

xcodebuild ${PROJECT_PARA}  -quiet  \
-scheme ${TARGET} archive   \
-archivePath `pwd`/archiveDir \
-configuration Release        \
DEVELOPMENT_TEAM=36PUU93BJ2

echo "=================== create plist  @ `date`==================="
cat <<EOF >export.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<key>teamID</key>
<string>36PUU93BJ2</string>
<key>method</key>
<string>enterprise</string>
</dict>
</plist>
EOF

echo "=================== exportArchive demo @ `date`==================="
if which xcbuilds > /dev/null 2>&1; then
# rvm issue https://openradar.appspot.com/28726736
# [xcbuilds](https://github.com/fastlane/fastlane/blob/master/gym/lib/assets/wrap_xcodebuild/xcbuild-safe.sh)
XCB=xcbuilds
else
XCB=xcodebuild
fi
${XCB} -exportArchive -exportPath . \
-archivePath archiveDir.xcarchive  \
-exportOptionsPlist  export.plist

echo "=================== upload ipa  @ `date`==================="
curl -F "file=@`pwd`/${TARGET}.ipa" \
-F "uKey=${USER_KEY}" \
-F "_api_key=${API_KEY}" \
https://qiniu-storage.pgyer.com/apiv1/app/upload

rm -rf export.plist
rm -rf archiveDir.xcarchive
rm -rf ${TARGET}.ipa
echo "===================modify podspec=================="
PlistBuddy="/usr/libexec/PlistBuddy"
plistFile=$(find ${TARGET} -name "Info.plist")
echo "plistFile -- $plistFile"
#获取工程版本号
version=$($PlistBuddy -c "Print :CFBundleShortVersionString" $plistFile)
echo "version -- $version"

sed "s@(s.version.*=) \"[.0-9]*\"@\1 \"$version\"@" \
../*.podspec

echo "=================== upload github==================="
cd ..
git add *
git commit -a -m "modify spec"
git tag $version
git push github $version
echo "upload github success"
echo "=================== 发布到cocoapod==================="
pod trunk push *.podspec --allow-warnings --verbose
echo "=================== done  @ `date` ==================="
