#!/bin/bash
# Customized version of https://github.com/lindwurm/madoka/blob/main/build.sh
SCRIPT_DIR=$(cd $(dirname "$0") || exit; pwd)
# ビルド用
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export ALLOW_MISSING_DEPENDENCIES=true
export SOONG_ALLOW_MISSING_DEPENDENCIES=true
export SELINUX_IGNORE_NEVERALLOWS=true
export CCACHE_DIR=/ccache
export USE_CCACHE=1

# 作っとく
mkdir -p /log/success /log/fail
# 実行時の引数が正しいかチェック
if [ $# -lt 2 ]; then
	echo "指定された引数は$#個です。" 1>&2
	echo "仕様: $CMDNAME [ビルドディレクトリ] [ターゲット] [オプション]" 1>&2
        echo "  -s: repo sync " 1>&2
        echo "  -c: make clean" 1>&2
	echo "ログは自動的に記録されます。" 1>&2
	exit 1
fi

builddir=$1
device=$2
shift 2

while getopts :tsc argument; do
case $argument in
	s) sync=true ;;
	c) clean=true ;;
	*) echo "正しくない引数が指定されました。" 1>&2
	   exit 1 ;;
esac
done

cd /"$builddir" || exit
ccache -M 30G

# repo sync
if [ "$sync" = "true" ]; then
	repo sync -j8 -c --force-sync --no-clone-bundle
	echo -e "\n"
	if [ $? -ne 0 ]; then
  		echo "repo sync failed!"
		exit 1
	fi
fi

# 現在日時取得、ログのファイル名設定
starttime=$(date '+%Y/%m/%d %T')
filetime=$(date -u '+%Y%m%d_%H%M%S')
filename="${filetime}_${builddir}_${device}.log"

# いつもの
source build/envsetup.sh
breakfast "$device"
vernum="$(get_build_var FLOKO_VERSION)"
source="floko-v${vernum}"
short="${source}"
zipname="$(get_build_var LINEAGE_VERSION)"
newzipname="Floko-v${vernum}-${device}-${filetime}-$(get_build_var FLOKO_BUILD_TYPE)"
# make clean
if [ "$clean" = "true" ]; then
        make clean
        echo -e "\n"
fi

# ビルド
make -j16 bacon 2>&1 | tee "/log/$filename"

if [ $(echo "${PIPESTATUS[0]}") -eq 0 ]; then
	ans=1
	statusdir="success"
	endstr=$(tail -n 3 "/log/$filename" | tr -d '\n' | sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' | sed 's/#//g' | sed 's/make completed successfully//g' | sed 's/^[ ]*//g')
	statustw="${zipname} のビルドに成功しました！"
else
	ans=0
	statusdir="fail"
	endstr=$(tail -n 3 "/log/$filename" | tr -d '\n' | sed -r 's/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g' | sed 's/#//g' | sed 's/make failed to build some targets//g' | sed 's/^[ ]*//g')
	statustw="${device} 向け ${source} のビルドに失敗しました…"
fi

cd ..

echo -e "\n"

# ログ移す
mv -v /log/"$filename" /log/$statusdir/

echo -e "\n"

# ビルドが成功してたら
if [ $ans -eq 1 ]; then
	# リネームする
	mv -v --backup=t "$builddir"/out/target/product/"$device"/"${zipname}".zip /output/"${newzipname}".zip
fi
