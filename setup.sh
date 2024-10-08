#!/data/data/com.termux/files/usr/bin/bash -e
# Copyright © 2024 by NurMi. All rights reserved.
#
# Email : support@nurmi.com
################################################################################

# colors

red='\033[1;31m'
yellow='\033[1;33m'
blue='\033[1;34m'
reset='\033[0m'


# Reset Kit

DESTINATION=${PREFIX}/share/TermuxAlpine
choice=""
if [ -d ${DESTINATION} ]; then
	printf "${red}[!] ${yellow}Setup in check and failed (YES/NO)? :${reset} "
	read choice
	if [ "${choice}" = "yes" ]; then
		rm -rf ${DESTINATION}
	elif [ "${choice}" = "no" ]; then
		exit 1
	else
		printf "${red}[!] Wrong input${reset}"
		exit 1
	fi

fi
mkdir ${DESTINATION}
cd ${DESTINATION}

# Setup Error Kit

unknownarch() {
	printf "$yellow"
	echo "[!] Error Archive"
	printf "$reset"
	exit 1
}

# Detect Kit

checksysinfo() {
	printf "$blue [*] Checking file downloading..."
	case $(getprop ro.product.cpu.abi) in
		arm64-v8a)
			SETARCH=aarch64
			;;
		armeabi|armeabi-v7a)
			SETARCH=armhf
			;;
		x86|i686)
			SETARCH=x86
			;;
		x86_64)
			SETARCH=x86_64
			;;
		*)
			unknownarch
			;;
	esac
}

# Check Kit

checkdeps() {
	printf "${blue}\n"
	echo " [*] Updating apt cache..."
	apt update -y &> /dev/null
	echo " [*] Checking for all required tools..."

	for i in proot bsdtar curl; do
		if [ -e ${PREFIX}/bin/$i ]; then
			echo " • $i is OK"
		else
			echo "Installing ${i}..."
			apt install -y $i || {
				printf "$red"
				echo " ERROR: check your internet connection or apt\n Exiting..."
				printf "$reset"
				exit 1
			}
		fi
	done
}

# Site Termux App

seturl() {
	ALPINE_VER=$(curl -s http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/$SETARCH/latest-releases.yaml | grep -m 1 -o version.* | sed -e 's/[^0-9.]*//g' -e 's/-$//')
	if [ -z "$ALPINE_VER" ] ; then
		exit 1
	fi
	ALPINE_URL="http://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/$SETARCH/alpine-minirootfs-$ALPINE_VER-$SETARCH.tar.gz"
}

# TAR Kit

gettarfile() {
	printf "$blue [*] Getting tar file...$reset\n\n"
	seturl $SETARCH
	curl --progress-bar -L --fail --retry 4 -O "$ALPINE_URL"
	rootfs="alpine-minirootfs-$ALPINE_VER-$SETARCH.tar.gz"
}

# SHA Kit

getsha() {
	printf "\n${blue} [*] Getting SHA ... $reset\n\n"
	curl --progress-bar -L --fail --retry 4 -O "${ALPINE_URL}.sha256"
}

# Check Inter Kit

checkintegrity() {
	printf "\n${blue} [*] Checking integrity of file...\n"
	echo " [*] The script will immediately terminate in case of integrity failure"
	printf ' '
	sha256sum -c ${rootfs}.sha256 || {
		printf "$red Sorry :( to say your downloaded linux file was corrupted or half downloaded, but don't worry, just rerun my script\n${reset}"
		exit 1
	}
}

# TAR Kit

extract() {
	printf "$blue [*] Extracting... $reset\n\n"
	proot --link2symlink -0 bsdtar -xpf $rootfs 2> /dev/null || :
}

# Log In Kit

createloginfile() {
	bin=${PREFIX}/bin/startalpine
	cat > $bin <<- EOM
#!/data/data/com.termux/files/usr/bin/bash -e
unset LD_PRELOAD
# thnx to @j16180339887 for DNS picker
addresolvconf ()
{
  android=\$(getprop ro.build.version.release)
  if [ \${android%%.*} -lt 8 ]; then
  [ \$(command -v getprop) ] && getprop | sed -n -e 's/^\[net\.dns.\]: \[\(.*\)\]/\1/p' | sed '/^\s*$/d' | sed 's/^/nameserver /' > \${PREFIX}/share/TermuxAlpine/etc/resolv.conf
  fi
}
addresolvconf
exec proot --link2symlink -0 -r \${PREFIX}/share/TermuxAlpine/ -b /dev/ -b /sys/ -b /proc/ -b /sdcard -b /storage -b \$HOME -w /home /usr/bin/env TMPDIR=/tmp HOME=/home PREFIX=/usr SHELL=/bin/sh TERM="\$TERM" LANG=\$LANG PATH=/bin:/usr/bin:/sbin:/usr/sbin /bin/sh --login
EOM

	chmod 700 $bin
}

# Checking TSAPK

finalwork() {
	[ ! -e ${DESTINATION}/finaltouchup.sh ] && curl --silent -LO https://raw.githubusercontent.com/Hax4us/TermuxAlpine/master/finaltouchup.sh
	if [ "${MOTD}" = "ON" ]; then
		bash ${DESTINATION}/finaltouchup.sh --add-motd
	else
		bash ${DESTINATION}/finaltouchup.sh
	fi
	rm ${DESTINATION}/finaltouchup.sh
}



# Clean Up Kit

cleanup() {
	if [ -d ${DESTINATION} ]; then
		rm -rf ${DESTINATION}
	else
		printf "$red not installed so not removed${reset}\n"
		exit
	fi
	if [ -e ${PREFIX}/bin/startalpine ]; then
		rm ${PREFIX}/bin/startalpine
		printf "$yellow uninstalled :) ${reset}\n"
		exit
	else
		printf "$red not installed so not removed${reset}\n"
	fi
}

printline() {
	printf "${blue}\n"
	echo " #------------------------------------------#"
}

usage() {
	printf "${yellow}\nUsage: ${green}bash TermuxAlpine.sh [option]\n${blue}  --uninstall		uninstall alpine\n  --add-motd		create motd file\n${reset}\n"
}

# Start

MOTD="OFF"
EXTRAARGS="default"
if [ ! -z "$1" ]
	then
	EXTRAARGS=$1
fi
if [ "$EXTRAARGS" = "--uninstall" ]; then
	cleanup
	exit 1
elif [ "$EXTRAARGS" = "--add-motd"  ]; then
	MOTD="ON"
elif [ $# -ge 1 ]
then
	usage
	exit 1
fi
printf "\n${yellow} You are going to install Studio in Termux Cool\n press ENTER to continue\n"
read enter

checksysinfo
checkdeps
gettarfile
getsha
checkintegrity
extract
createloginfile

printf "$blue [*] Configuring Termux Studio for you ..."
finalwork
printline
printf "\n${yellow} Now you can enjoy a very small (just 1 MB!) Linux environment in your Termux \n Don't forget to star my work\n"
printline
printline
printf "\n${blue} [*] Email   :${yellow}    lkpandey950@gmail.com\n"
printf "$blue [*] Website :${yellow}    https://hax4us.com\n"
printf "$blue [*] YouTube :${yellow}    https://youtube.com/hax4us\n"
printline
printf "$red \n NOTE : $yellow use ${red}--uninstall${yellow} option for uninstall\n"
printline
printf "$reset"
