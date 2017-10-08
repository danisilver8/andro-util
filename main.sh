#!/usr/bin/env bash

list-packages () {
	adb shell pm list packages | cut -d: -f2
}

pull (){
	# $1 - package name
	echo "pulling package $1"	
	path="$(adb shell pm path $1 | sed 's/package://g' | tr -d '\r' )"
	adb pull "$path" "$1.apk"
}

backsmali (){
	# $1 - apk path
	echo "Apk to smali"
	apktool d $1 > /dev/null
}

build (){
	# $1 - source folder to build
	# $2 - output apk name
	echo "Smali to apk"
	apktool b $1 -o $2 > /dev/null
}

sign (){
	# $1 - apk path
	keystore=".debug.keystore"

	if [ -f "$keysotre" ]
	then
		echo "found key"
	else
		echo "creating new key"
		keytool -genkeypair -keyalg RSA -alias androiddebugkey -keypass android -keystore $keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 > /dev/null
	fi

	jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -storepass android -keystore $keystore $1 androiddebugkey > /dev/null
}

install (){
	# $1 - apk to install
	adb install $1
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
