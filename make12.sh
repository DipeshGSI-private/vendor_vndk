#!/bin/bash

systempath=$1
thispath=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`

# Detect APEX State
if ! (ls $systempath/apex | grep -q ".apex$") ;then
   rm -rf $systempath/apex/com.android.vndk.current
   7z x -y $thispath/12/com.android.vndk.current.apex.7z -o$systempath/apex/ > /dev/null 2>&1
fi

# Clean up default apex state
sed -i '/ro.apex.updatable/d' $systemdir/build.prop
sed -i '/ro.apex.updatable/d' $systemdir/product/etc/build.prop
sed -i '/ro.apex.updatable/d' $systemdir/system_ext/etc/build.prop

apex_flatten() {
	# Force use flatten apex
  echo "" >> $systemdir/product/etc/build.prop
  echo "# Apex state" >> $systemdir/product/etc/build.prop  
  echo "ro.apex.updatable=false" >> $systemdir/product/etc/build.prop
  
  echo "$ENABLE_CLEAN_APEX_FILES"
  local apex_files=$(ls $systemdir/apex | grep ".apex$")
  for apex in $apex_files ;do
    if [ -f $systemdir/apex/$apex ];then
      rm -rf $systemdir/apex/$apex
    fi
  done

# Make VNDK symlinks
rm -rf $systempath/lib/vndk-30 $systempath/lib/vndk-sp-30
rm -rf $systempath/lib/vndk-29 $systempath/lib/vndk-sp-29
rm -rf $systempath/lib/vndk-28 $systempath/lib/vndk-sp-28
rm -rf $systempath/lib64/vndk-30 $systempath/lib64/vndk-sp-30
rm -rf $systempath/lib64/vndk-29 $systempath/lib64/vndk-sp-29
rm -rf $systempath/lib64/vndk-28 $systempath/lib64/vndk-sp-28

ln -s  /apex/com.android.vndk.v30/lib $systempath/lib/vndk-30
ln -s  /apex/com.android.vndk.v29/lib $systempath/lib/vndk-29
ln -s  /apex/com.android.vndk.v28/lib $systempath/lib/vndk-28
ln -s  /apex/com.android.vndk.v30/lib $systempath/lib/vndk-sp-30
ln -s  /apex/com.android.vndk.v29/lib $systempath/lib/vndk-sp-29
ln -s  /apex/com.android.vndk.v28/lib $systempath/lib/vndk-sp-28

ln -s  /apex/com.android.vndk.v30/lib64 $systempath/lib64/vndk-30
ln -s  /apex/com.android.vndk.v29/lib64 $systempath/lib64/vndk-29
ln -s  /apex/com.android.vndk.v28/lib64 $systempath/lib64/vndk-28
ln -s  /apex/com.android.vndk.v30/lib64 $systempath/lib64/vndk-sp-30
ln -s  /apex/com.android.vndk.v29/lib64 $systempath/lib64/vndk-sp-29
ln -s  /apex/com.android.vndk.v28/lib64 $systempath/lib64/vndk-sp-28

# Extract VNDK apex to system
7z x -y $thispath/12/com.android.vndk.v28.apex.7z -o$systempath/apex/ 2>/dev/null >> $systempath/zip.log
7z x -y $thispath/12/com.android.vndk.v29.apex.7z -o$systempath/apex/ 2>/dev/null >> $systempath/zip.log
7z x -y $thispath/12/com.android.vndk.v30.apex.7z -o$systempath/apex/ 2>/dev/null >> $systempath/zip.log
rm -rf $systempath/zip.log

  # Add aosp apex
  if ! apex_file ;then
    7z x -y $thispath/11/apex_common.7z -o$systempath/apex/ > /dev/null 2>&1
    android_art_debug_check() {
      apex_ls | grep -q "art.debug" 
    }
    android_art_release_check() {
      apex_ls | grep -q "art.release"
    }
    if android_art_debug_check ;then
      7z x -y $thispath/11/art.debug.7z -o$systempath/apex/ > /dev/null 2>&1
    fi

    if android_art_release_check ;then
      7z x -y $thispath/11/art.release.7z -o$systemdpath/apex/ > /dev/null 2>&1
    fi
  fi

# Fix vintf for different vndk version
manifest_file="$systempath/system_ext/etc/vintf/manifest.xml"
if [ -f $manifest_file ];then
   sed -i "/<\/manifest>/d" $manifest_file
   cat $thispath/12/manifest.patch >> $manifest_file
   echo "" >> $manifest_file
   echo "</manifest>" >> $manifest_file
fi
