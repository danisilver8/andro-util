#!/usr/bin/env bash

list-packages () {
	adb shell pm list packages | cut -d: -f2
}

pull (){
	# $1 - package name
	path="$(adb shell pm path $1 | sed 's/package://g' | tr -d '\r' )"
	adb pull "$path" "$1.apk"
}

backsmali (){
	# $1 - apk path
	# $2 - output smali name
	# $3 - output sources name
	echo "Apk to smali"
	smali=$2
	sources=$3
	mkdir $sources  
	unzip $1 -d $sources > /dev/null
	smali_disassemble $sources/classes.dex $smali
	# apktool d $1 > /dev/null
}

create_apk(){
	# $1 - source folder to build
	# $2 - smali folder to build 
	# $3 - output apk name
	build $1 $2 $3
	sign $3 
	mv $3 "unaligned-$3"
	align "unaligned-$3" $3
	rm "unaligned-$3"
}

build (){
	# $1 - source folder to build
	# $2 - smali folder to build 
	# $3 - output apk name
	echo "Smali to apk"
	smali_assemble $2 $1/classes.dex
	cd $1
	zip -r ../$3 AndroidManifest.xml classes.dex res resources.arsc > /dev/null
	cd -
	# apktool b $1 -o $2 > /dev/null
}

sign (){
	# $1 - apk path
	keystore=".debug.keystore"

	if [[ -e "$keystore" ]] ; then 
		echo "found key"
	else
		echo "creating new key"
		keytool -genkeypair -keyalg RSA -alias androiddebugkey -keypass android -keystore $keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999  > /dev/null
	fi

	jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -storepass android -keystore $keystore $1 androiddebugkey > /dev/null
}

align () {
	# $1 - apk to align
	# $2 - output apk name
	zipalign -v 4 $1 $2 > /dev/null
}

install (){
	# $1 - apk to install
	adb install -r $1
}

#### baksmali wrappers
smali_assemble () {
	java -jar $DIR/lib/smali-2.2.1.jar assemble $1 -o $2
}

smali_disassemble () {
	java -jar $DIR/lib/baksmali-2.2.1.jar disassemble $1 -o $2
}


demo () {
	echo "Hello World"
	pull com.android.insecurebankv2
	backsmali com.android.insecurebankv2.apk
	build com.android.insecurebankv2 app.apk
	sign app.apk
	install app.apk
	echo "done"
}

# demo
