#!/bin/bash
#
#	seed.sh
#

	var="$(date +%s)"


	LogFile=/var/log/seed.log

	coreAcct=di07zd4

	pkgTransportMethod=filesystem		#	"network" is also supported

	pkgTransportAddress=192.168.1.57

	pkgTransportPath=/media/zcore.d


	# jdk installation definitions
	jdkInstallMethod="net"




	if [ $# -lt 9 ]; then
		bDebugging=yes
	fi
	
	# prepare for hardware (hw) differences
	# =====================================
	hw=""
	dmesg 2>&1 | grep -i macbook		>	/dev/null	2>&1 
	if [ $? -eq 0 ]; then
		hw="macbookPro"	
	fi

	# prepare for distro differences
	# ==============================
	distro="null"
	extDistro="null"

	if grep -i ubuntu /etc/issue > /dev/null 2>&1; then
		distro=ubuntu
	fi

	if grep -i lmde /etc/issue > /dev/null	2>&1; then
		distro=lmde
		extDistro=debian
	fi

	if grep -i mint /etc/issue > /dev/null	2>&1; then
		distro=mint
	fi

	if grep -i solyd /etc/issue > /dev/null	2>&1; then
		distro=solyd
	fi

	if grep -i centos /etc/centos-release	> /dev/null 2>&1; then
		distro=centos
	fi

	if grep -i fedora /etc/issue > /dev/null 2>&1; then
		distro=fedora
	fi


	uname -a 2>&1 | grep -i sunos 		>	/dev/null	2>&1
	if [ $? -eq 0 ]; then
		distro=solaris
	fi


	if [ -z "$distro" ]; then
		exit 99
	fi

	if [ $distro = mint ] || [ $distro = solyd ] || [ $distro = ubuntu ]; then
		extDistro=mubu
	fi


	if [ $distro = lmde ]; then
		UPDATE="            apt-get -yuq update"
		DISTUPDATE="        apt-get -yuq upgrade"
		UPGRADE="echo I\n | apt-get -yuq upgrade"
		INSTALL="           apt-get -yuq install"
		REMOVE="            apt-get -yuq remove"
		DE=kde
		DE=none
	fi 


	if [ $distro = ubuntu ]; then
		UPDATE="apt-get  -y update"
		DISTUPDATE="apt-get  -y update"
		UPGRADE="apt-get -yu upgrade"
		INSTALL="apt-get -y install"
		REMOVE="apt-get -y remove"		
		DE=ubuntustudio
		DE=lmde
		DE=none
	fi 

	if [ $distro = solyd ]; then
		UPDATE="            apt-get -yuq update"
		DISTUPDATE="        apt-get -yuq upgrade"
		UPGRADE="echo I\n | apt-get -yuq upgrade"
		INSTALL="           apt-get -yuq install"
		REMOVE="            apt-get -yuq remove"
		DE=kde
		DE=none
	fi 

	if [ $distro = mint ]; then
		UPDATE="            apt-get -yuq update"
		DISTUPDATE="        apt-get -yuq install   mintupdate"
		UPGRADE="echo I\n | apt-get -yuq upgrade"
		INSTALL="           apt-get -yuq install"
		REMOVE="            apt-get -yuq remove"
		DE=xfce
		DE=none
	fi 

	if [ $distro = centos ]; then
		DISTUPDATE="yum  -y update"
		UPDATE="yum  -y update"
		UPGRADE="yum -y update"
		INSTALL="yum -y install"
		REMOVE="yum -y remove"
		DE=kde
		DE=none
	fi 

	if [ $distro = fedora ]; then
		DISTUPDATE="yum  -y update"
		UPDATE="yum  -y update"
		UPGRADE="yum -y update"
		INSTALL="yum -y install"
		DE=xfce
		DE=none
	fi 


allowForDebugging()
{
	if [ "$bDebugging" = yes ]; then
        	turnOnDebugging
	fi
	return
}


turnOnDebugging()
{
        set -x
	echo "debugging : now ON"			>	/dev/null
        return 0
}


turnOffDebugging()
{
        set +x
        return 0
}


addToLog()
{
	postToLog "$1"
	return 0
}

postToLog()
{
	printf "$1\n"					>>	$LogFile	2>&1
	return 0
}


post()
{
	printf "$1\n"
	postToLog "$1"
	return 0
}

touchLog()
{
	touch		$LogFile			>	/dev/null	2>&1
	chmod 644	$LogFile			>	/dev/null	2>&1
	return 0
}

clearLog()
{
	> $LogFile	2>&1
	return 0
}

viewLog()
{
	view $LogFile
	return 0
}


postTime()
{
	varDate="$(date)"
	post "$varDate" 
	return 0
}

postTimeToLog()
{
	varDate="$(date)"
	postToLog "$varDate"
	return 0
}

addTimeToLog()
{
	postTimeToLog
	return 0
}

stringAContainsStringB()
{
	allowForDebugging

	if printf "$1" 2> /dev/null | grep "$2" > /dev/null; then
		return true
	else
		return false
	fi
}



aptitudeInstalled()
{
	allowForDebugging

    if !  aptitude search '~i!~M'  > /dev/null  2>&1; then
        post "critical error : aptitude is not installed"
        return 9
    fi

    turnOffDebugging

	return 0
}




pkgInstalled()
{
	allowForDebugging

    # related cmd saved as reference 	
    # if ! dpkg --get-selections | grep -v deinstall | grep -iE  $pkg

	if [ -z "$1" ]; then
		post "usage : pkgInstalled  pkgName (pkgName arg is required) - exit=9"
		exit 9
	fi

	if ! `echo "$distro" | grep -i "ubuntu"`; then
		post "INFO : add support for non-ubuntu distros ... exit=9"
        exit 9
	fi

    pkg="$1"
    
    if ! aptitude show $pkg > /dev/null  2>&1; then
        # if ! dpkg --get-selections | grep -v deinstall | grep -iE  $pkg > /dev/null  2>&1; then      
        return 1
    fi

    aptitude show $pkg 2>&1 | grep "not installed" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        return 1
    fi

    # we know, at this point ... the pkg is installed

    turnOffDebugging

	return 0
}




buildPkgTransportUrls()
{
        post "setup the new pkg variables"

	found=false

	if stringAContainsStringB $pkgTransportMethod "net" > /dev/null; then
		found=true
	fi

	if stringAContainsStringB $pkgTransportMethod "file" > /dev/null; then
		found=true
	fi

	if ! found; then
		post "pkgTransportMethod not supported <$pkgTransportMethod>"
		exit 199
	fi


	if stringAContainsStringB  $pkgTransportMethod "net" > /dev/null; then
		pkgTransportCoreUrl="$pkgTransportAddress"
	fi

	if stringAContainsStringB  $pkgTransportMethod "file" > /dev/null; then
		pkgTransportCoreUrl="$pkgTransportPath"
	fi


	pkgTransportUrl="$pkgTransportCoreUrl/media.d/installMedia.d"
	export pkgTransportUrl


	turnOffDebugging
	return 0
}


getNetInfo()
{
	allowForDebugging

	dev=`ifconfig -s 2>&1 | egrep -v "^Iface|^lo" | head -1 | cut -f1 -d' '`

	# next, check for string length of zero in the string we just created
	if [ "${#dev}" -eq 0 ]; then
		addToLog "failure to obtain dev name in logNetworkInfo function"
		exit 89
	fi

	addToLog "obtained [ ${dev} ] as our network device [ var=gvNetDevice ]"

	gvNetDevice="${dev}"
	export gvNetDevice

	turnOffDebugging
	return 0
}



logDistroInfo()
{
	allowForDebugging

	addToLog "distro = [ ${distro} ]"

	turnOffDebugging
	return 0
}



updateTheSystem()
{
	allowForDebugging

	$UPDATE 2>&1 | tee -a					$LogFile

	turnOffDebugging
	return 0
}



reviewThisForUseWithUpdatesLater()
{
	for i in 1 2
		do
		# "distribution update" here
		# $DISTUPDATE 2>&1 | tee -a				$LogFile
		echo > /dev/null
		status="$?"
		if [ $status -gt 0 ]
			then
			addToLog "dist update failure ($status) ..."
			addTimeToLog
			return 1
		fi

		#	DEBIAN_FRONTEND=noninteractive apt-get upgrade -f -y --force-yes --quiet --yes

		# upgrade here
		if [ $distro = "mint" ]; then
			addToLog "apt-get upgrade exec ..."
			echo > /dev/null
			#	echo "I\nI\nI\nI\nI\n" | apt-get -yuq upgrade 2>&1 | tee -a	$LogFile
			status="$?"
		fi

		# this status is "no good," since the tee command is used above
		status="$?"
		if [ $status -gt 0 ]
			then
			addToLog "dist upgrade failure ($status) ..."
			addTimeToLog
			return 1
		fi

		$UPDATE 2>&1 | tee -a					$LogFile
		status="$?"
		if [ $status -gt 0 ]
			then
			addToLog "update failure ($status) ..."
			addTimeToLog
			return 1
		fi
		done
	#for

	return 0
}


seed()
{
	allowForDebugging

	addToLog "setting up new system ($distro) ..."
	addTimeToLog

	reviewForSpecificHardware


	if [ $distro = "mint" ]; then
		addToLog "adding debconf-utils to the new mint system ..."
		for Pkg in debconf-utils
			do
			$INSTALL $Pkg	2>&1 | tee -a		$LogFile
			done
		#for
	fi


	if [ $distro = "suse" ]; then
		addToLog "adding basic tools to the new mint system ..."
		for Pkg in gcc make kernel-default-devel
			do
			$INSTALL $Pkg	2>&1 | tee -a		$LogFile
			done
		#for
	fi


	updateTheSystem


#	if [ $extDistro = "mubu" ]; then
#		addToLog "adding the repos for chrome ..."	
#		add-apt-repository "deb http://dl.google.com/linux/chrome/deb/ stable main"
#		wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
#		updateTheSystem
#	fi


	if [ $DE != "none" ]; then
		addToLog "adding $DE to the new system ..."
		addTimeToLog
		$INSTALL	$DE-desktop			>>	$LogFile	2>&1
		status="$?"
		if [ $status -gt 0 ]
			then
			addToLog "$DE add failure ($status) ..."
			addTimeToLog
			return 2
		fi
	fi


	if [ $DE != "kde" ]; then
		addToLog "adding tools to non-kde system ..."
		addTimeToLog
		# $INSTALL	konsole k3b			>>	$LogFile	2>&1
		status="$?"
		if [ $status -gt 0 ]
			then
			addToLog "tools add failure ($status) ..."
			addTimeToLog
			return 2
		fi
	fi


	if [ $extDistro = "mubu" ]; then
		addToLog "adding misc tools to the new system ..."
		addTimeToLog
		
		# "xfce-notes" pkg may need to be added later
		
		BaseSet="build-essential linux-headers-`uname -r` dkms"
        ToolsSet="ufw gufw geany chromium-browser"
		SambaSet="samba system-config-samba cifs-utils winbind fuse gvfs-backends"
		#SambaSet=" "
		
		for pkg in $BaseSet  $ToolsSet  $SambaSet
			do
			addToLog "======================================="
			addToLog "$pkg : adding..."
			addToLog "======================================="			
			
			#$INSTALL "$pkg" >> $LogFile	2>&1
			aptitude -y install "$pkg" >> $LogFile	2>&1			
			status="$?"
			if [ $status -gt 0 ]
				then
				addToLog "$pkg : install failure, status = $status"
				addTimeToLog
				return 2
			fi
			addToLog "$pkg : successful consideration"			
			done
		#for

		#	ensure that samba starts on boot
		update-rc.d samba defaults 	| tee -a		$LogFile

		#	ensure that samba requests are allow through the firewall
		ufw allow Samba 			| tee -a 		$LogFile


		for rmvPkg in firefox firefox-locale-en
			do
			addToLog "======================================="
			addToLog "removing $rmvPkg ..."
			addToLog "======================================="				
			
			if ! aptitude -y remove "$rmvPkg" >> $LogFile	2>&1; then
				addToLog "${rmvPkg} : removal failure ($status) ..."
				addTimeToLog
				return 2
			fi
			done
		#for
	fi

	if [ $distro = "fedora" ]; then
		addToLog "adding misc tools to the new system ..."
		addTimeToLog
		
		# "xfce-notes" pkg may need to be added later
		$INSTALL geany gcc kernel-devel kernel-headers dkms make bzip2 perl >> $LogFile 2>&1
		status="$?"
		if [ $status -gt 0 ]
			then
			addToLog "tools add failure ($status) ..."
			addTimeToLog
			return 2
		fi
	fi

	if [ $distro = "solaris" ]; then
		addToLog "adding misc tools to the new system ..."
		addTimeToLog
		
		# "xfce-notes" pkg may need to be added later
		$INSTALL gcc gcc-c++ bash 	2>&1 | tee -a		$LogFile
		status="$?"
		if [ $status -gt 0 ]
			then
			addToLog "tools add failure ($status) ..."
			addTimeToLog
			return 2
		fi
	fi


	echo "rebooting new system ..."	2>&1 | tee -a		$LogFile
	date 							2>&1 | tee -a		$LogFile
	#	reboot

	turnOffDebugging
	return 0
}


sh -c "cat > /dev/null"<<EOF


# =========================================================================================================

Launch Gigolo

Menu button -> System -> Gigolo

	Toolbar Gigolo: Edit -> Preferences -> tab Interface

	Check:
		- Start minimized in the Notification Area
		- Show side panel

	Uncheck:
		- Show auto-connect error messages

	Click the tab Toolbar -> Style: set to Both

	Click Close to leave the Preferences.

Now click on the tab Network (vertical text) on the left.

	Then you see the available network, with the network disk.

	Right-click on the disk and select Create Bookmark.

	Now the "Edit Bookmark" window pops up.  In that window, check: Auto-Connect. 

Toolbar Gigolo -> Edit -> Preferences -> tab General -> Bookmark Auto-Connect Interval).

Gigolo has been configured.

# =========================================================================================================

EOF



mintWs()
{
	allowForDebugging

	sessionCore=mintWs
	sessionDesc="mint-based workstation"

	addToLog "setting up $sessionCore ($sessionDesc) support ..."
	addTimeToLog

	if [ $distro != "mint" ]; then
		return 39
	fi

	$UPDATE						>>	$LogFile	2>&1

	for Pkg in qt-sdk virtualbox-qt
		do
		$INSTALL	$Pkg			>>	$LogFile	2>&1
		echo "pkg install status = $?"		>>	$LogFile	2>&1
		done
	#for

	$UPDATE 2>&1 | tee -a					$LogFile

	addToLog "$session logic completed ..."
	addTimeToLog

        turnOffDebugging
	return 0
}

mintLAMP()
{
        allowForDebugging

	sessionCore=mintLAMP
	sessionDesc="mint-based LAMP server"

        addToLog "setting up $sessionCore ($sessionDesc) support ..."
	addTimeToLog

        if [ $distro != "mint" ]; then
                return 39
        fi

	$UPDATE 2>&1 | tee -a					$LogFile

	DEBCONF="debconf-set-selections"


	#debconf-set-selections <<< 'mysql-server mysql-server/root_password password your_password'
	#$DEBCONF <<< 'mysql-server mysql-server/root_password       password pass'
	#$DEBCONF <<< 'mysql-server mysql-server/root_password_again password pass'

	for Pkg in "lamp-server^" phpmyadmin
               do
               $INSTALL        "$Pkg" 2>&1 | tee -a		$LogFile
               addToLog "pkg install status = $?"
               done
        #for

	$UPDATE 2>&1 | tee -a					$LogFile

	/etc/init.d/apache2 restart			>>	$LogFile	2>&1

	ufw allow proto tcp from 192.168.1.0/24 to any port mysql

	#	php -r 'echo "\n\nYour PHP installation is working fine.\n\n\n";'

	addToLog "$sessionCore logic completed ..."
	addTimeToLog

        turnOffDebugging
        return 0
}




mintFsrv()
{
        allowForDebugging

	addToLog "setting up mintSrv (mint-based file server) support ..."
	addTimeToLog

	if [ $distro != "mint" ]; then
		return 39
	fi

	$UPDATE 2>&1 | tee -a					$LogFile

	# gadmin-samba is another (thorough) option for managing samba settings
	# system-config-samba definitly works for managing samba settings
	for Pkg in samba system-config-samba cifs-utils winbind
		do
		$INSTALL	$Pkg			>>	$LogFile	2>&1
		echo "pkg install status = $?"		>>	$LogFile	2>&1
		done
	#for

	#	ensure that samba starts on boot
	update-rc.d samba defaults 	| tee -a		$LogFile

	#	ensure that samba requests are allow through the firewall
	ufw all Samba 			| tee -a 		$LogFile

	$UPDATE 2>&1 			| tee -a		$LogFile

	echo "mintSrv logic completed ..."		>>	$LogFile	2>&1
	addTimeToLog

	turnOffDebugging
	return 0
}




fedFsrv()
{
	allowForDebugging

	addToLog "setting up fedFSrv (fedora-based file server) support ..."
	addTimeToLog

	if [ $distro != "fedora" ]; then
		return 39
	fi

	$UPDATE 2>&1 | tee -a					$LogFile

	# gadmin-samba is another (thorough) option for managing samba settings
	# system-config-samba definitly works for managing samba settings
	for Pkg in samba system-config-samba cifs-utils winbind
		do
		$INSTALL	$Pkg			>>	$LogFile	2>&1
		echo "pkg install status = $?"		>>	$LogFile	2>&1
		done
	#for

	#	ensure that samba starts on boot
	#	update-rc.d samba defaults 	| tee -a		$LogFile

	#	ensure that samba requests are allow through the firewall
	#	ufw all Samba 			| tee -a 		$LogFile

	$UPDATE 2>&1 			| tee -a		$LogFile

	echo "fedFSrv logic completed ..."		>>	$LogFile	2>&1
	addTimeToLog

	turnOffDebugging
	return 0
}




macUbuntu()
{
        allowForDebugging

	addToLog "setting up macUbuntu support ..."
	addTimeToLog

	if [ $distro != "ubuntu" ]; then
		return 39
	fi

	echo "\n" | add-apt-repository	\
				ppa:docky-core/ppa	>>	$LogFile	2>&1
	$UPDATE						>>	$LogFile	2>&1
	$INSTALL		docky			>>	$LogFile	2>&1

	echo "\n" | add-apt-repository	\
				ppa:noobslab/themes	>>	$LogFile	2>&1
	$UPDATE						>>	$LogFile	2>&1
	echo "\n" | $INSTALL	mac-ithemes-v3		>>	$LogFile	2>&1
	echo "\n" | $INSTALL	mac-icons-v3		>>	$LogFile	2>&1
	echo "\n" | $INSTALL	mbuntu-bscreen-v3	>>	$LogFile	2>&1
	echo "\n" | $INSTALL	mbuntu-lightdm-v3	>>	$LogFile	2>&1

	#	echo "\n" | add-apt-repository	\
	#			ppa:noobslab/apps	>>	$LogFile	2>&1
	#	echo "\n" | $INSTALL	\
	#			indicator-synapse	>>	$LogFile	2>&1
	
	echo "macUbuntu logic completed ..."		>>	$LogFile	2>&1
	addTimeToLog

        turnOffDebugging
	return 0
}






allowForMacbookPro()
{
        allowForDebugging

	if [ $hw != "macbookPro" ]; then
		return 0;
	fi	
		
	if [ $distro != "fedora" ]; then
		return 49
	fi

	if [ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]; then
		echo -n 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
	fi

	lsmod  2> /dev/null | grep -i wl		>	/dev/null	2>&1 
	status="$?"

	if [ $status -gt 0 ]; then
		yum -y install 	akmod-wl
		modprobe wl
	fi		
	
	
	grep -i TapButton1 $HOME/.bashrc		>	/dev/null	2>&1 
	status="$?"

	if [ $status -gt 0 ]; then
		echo "synclient TapButton1=1"		>>	$HOME/.bashrc	2>&1
	fi

        turnOffDebugging
	return 0
}



install_virtualbox()
{
        allowForDebugging

	cd /etc/yum.repos.d/

	wget http://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo

	yum -y install	\
		VirtualBox		
	
	service vboxdrv setup

	usermod -a -G vboxusers iansblues

	turnOffDebugging
	
	return 0
}


install_media()
{
        allowForDebugging

	sudo yum -y install														\
		libdvdread libdvdnav lsdvd											\
		gstreamer gstreamer-plugins-base									\
		gstreamer-plugins-good gstreamer-plugins-bad gstreamer-plugins-ugly \
		gstreamer-ffmpeg ffmpeg ffmpeg-libs libdvbpsi						\
		xine-lib-extras xine-lib-extras-freeworld							\
		udacious-plugins-freeworld-mp3 xmms-mp3 k3b-extras-freeworld		\
		totem-nautilus totem-mozplugin totem-pl-parser

	sudo yum -y install	\
		vlc

        turnOffDebugging
	return 0
}



install_apps()
{
        allowForDebugging
	sudo yum -y install	\
		libreoffice-writer	libreoffice-calc	choqok		k3b

        turnOffDebugging
	return 0
}



install_network()
{
        allowForDebugging

	systemctl stop		NetworkManager
	
	yum -y remove		NetworkManager


	systemctl enable	network
	systemctl restart	network

	systemctl status 	network
	systemctl status 	iptables

	# be sure to supply a network config file in /etc/sysconfig/network-scripts
	#     examples are stored in xt57.d/admin.d/conf.d

        turnOffDebugging
	return 0
}






install_qt()
{
        allowForDebugging
	sudo yum -y erase	\
		qt-devel qt-mysql qt-examples qt-doc qt-config qt-creator



	sudo yum -y install	\
		make	gcc-c++

	#	sudo yum -y install	\
	#		qt-devel qt-mysql qt-examples qt-doc qt-config qt-creator

	#	be sure to now install the .bashrc file from xt57.d's admin.d/conf.d dir

        turnOffDebugging

	return 0
}








install_httpd()
{
        allowForDebugging

	for Pkg in   httpd
		do
		systemctl stop		$Pkg.service
		echo; echo
		systemctl disable	$Pkg.service
		echo; echo
		systemctl status	$Pkg.service
		done
	#endfor


	yum -y erase    httpd-tools
	yum -y erase    httpd
	yum -y erase    phpmyadmin        php-mysql      php         php-common

	yum -y list installed | grep php |
		while read Pkg
		do
		yum -y erase $Pkg		>	/dev/null	2>&1
		done
	#endpipe


	# load repos entries
	# ==================
	Prefix=download1.rpmfusion.org
	Free=/free/fedora/rpmfusion-free-release-stable
	NonFree=/nonfree/fedora/rpmfusion-nonfree-release-stable
	Noarch=noarch.rpm

	rpm -Uvh 	http://$Prefix/$Free.$Noarch
	rpm -Uvh 	http://$Prefix/$NonFree.$Noarch

	rpm -Uvh http://rpms.famillecollet.com/remi-release-20.rpm




        echo; echo; echo; echo

	yum -y	--enablerepo=remi	\
		install   httpd

	yum -y	--enablerepo=remi	\
		install   php   php-common

	yum -y	--enablerepo=remi							\
		install php-pecl-apc php-cli php-pear php-pdo php-mysqlnd php-pgsql	\
		php-pecl-mongo php-sqlite php-pecl-memcache php-pecl-memcached		\
		php-gd php-mbstring php-mcrypt php-xml


	for Pkg in   httpd
		do
		systemctl stop		$Pkg.service
		echo; echo
		systemctl start		$Pkg.service
		echo; echo
		systemctl enable	$Pkg.service
		echo; echo
		systemctl status	$Pkg.service
		done
	#endfor

        turnOffDebugging
	return 0
}







install_mysql()
{
        allowForDebugging

	yum -y 	install   mariadb mariadb-server mariadb-libs

	yum -y	install   php-mysqlnd

	yum -y	install   phpMyAdmin

	for Pkg in    mariadb
		do
		systemctl restart	$Pkg.service
		echo; echo
		systemctl enable	$Pkg.service
		echo; echo
		systemctl status	$Pkg.service
		done
	#endfor

	firewall-cmd --permanent --zone=public --add-service=mysql

	#	systemctl restart iptables.service

        turnOffDebugging
	return 0
}


miscTests()
{
        allowForDebugging

        sessionCore=miscTests
        sessionDesc="miscTests"

        addToLog "running $sessionCore session ..."
	addTimeToLog

        if [ $distro != "mint" ]; then
                return 39
        fi

	/etc/init.d/apache2 status			>>	$LogFile	2>&1	
	/etc/init.d/apache2 status

        php -r 'echo "\n\nYour PHP installation is working fine.\n\n\n";'

        addToLog "$sessionCore logic completed ..."
	addTimeToLog

        turnOffDebugging
        return 0
}


netConfig()
{
        allowForDebugging

        funName=netConfig

        addToLog "running $funName ..."
	addTimeToLog

        if [ $distro != "centos" ]; then
        	addToLog "OS deemed to be other than centos ..."
                return
        fi

	echo "Enter hostname and final octet : \c"
	read s

	hostName=`echo ${s} | cut -f1 -d',' | tr -d ' '`
	finalOctet=`echo ${s} | cut -f2 -d',' | tr -d ' '`

	getNetInfo

	chkconfig --list	NetworkManager		>>	$LogFile	2>&1

	service			NetworkManager	stop	>>	$LogFile	2>&1

	chkconfig		NetworkManager	off	>>	$LogFile	2>&1

	service			network		start	>>	$LogFile	2>&1

	chkconfig		network		on	>>	$LogFile	2>&1

	ls -ltr /etc/sysconfig/network-scripts/		>>      $LogFile        2>&1

	netConfigPath="/etc/sysconfig/network-scripts/ifcfg-${gvNetDevice}"
        addToLog "netConfigPath = [ ${netConfigPath} ]"
	addTimeToLog

	netHostsPath="/etc/hosts"
        addToLog "netHostsPath = [ ${netHostsPath} ]"
	addTimeToLog

	netDnsPath="/etc/resolv.conf"
        addToLog "netDnsPath = [ ${netDnsPath} ]"
	addTimeToLog


#	populate the sysconfif ip setup file

sh -c "cat > ${netConfigPath}"<<EOF
TYPE=Ethernet
DEVICE=${gvNetDevice}
ONBOOT=yes
BOOTPROTO=none
IPADDR=192.168.1.${finalOctet}
GATEWAY=192.168.1.1
EOF




#	populate the hosts file

sh -c "cat > ${netHostsPath}"<<EOF
# supplied by xt57 logic
127.0.0.1       localhost
192.168.1.${finalOctet}   ${hostName}.xt57.net           ${hostName}
EOF




#	populate the rsolv.conf file

sh -c "cat > ${netDnsPath}"<<EOF
# supplied by xt57 logic
search xtdns.xt57.net xt57.net
nameserver 192.168.1.99
EOF


	service			network		restart	>>	$LogFile	2>&1

	ifconfig					>>	$LogFile	2>&1

	traceroute		www.google.com		>>	$LogFile	2>&1
	
	ifconfig -s 2>&1 | egrep -v "^Iface|^lo" | head -1

	ifconfig | grep "${finalOctet}"

	uname -a	

        addToLog "$funName completed ..."
        addTimeToLog

        turnOffDebugging
        return 0
}




jboss()
{
        allowForDebugging

	addToLog "setting up JBoss support ..."
	addTimeToLog

	if [ $distro != "centos" ]; then
		return 43
	fi

	logDistroInfo

	logNetworkInfo

	addToLog "persistent net dev name = ${varDev}"

	exit 0

	updateTheSystem

	for Pkg in java-1.6.0-openjdk-devel
		do
		$INSTALL	$Pkg			>>	$LogFile	2>&1
		echo "pkg install status = $?"		>>	$LogFile	2>&1
		done
	#for

	updateTheSystem

	java -version				| tee -a	$LogFile	

	dstDir="/home/iansblues/Downloads"
	url="http://download.jboss.org/jbossas/7.1/jboss-as-7.1.1.Final/jboss-as-7.1.1.Final.zip"

	wget -P "$dstDir" "$url"		| tee -a	$LogFile	
	addToLog "jboss wget status = $?"

	prodName="jboss-as-7.1.1.Final"
	srcZip="$dstDir/$prodName.zip"

	adduser jboss				| tee -a	$LogFile
	addToLog "jboss adduser status = $?"

	jbossHome="/home/jboss"
	jbossDir="/home/jboss/$prodName"

	unzip -d "$jbossHome" "$srcZip"		| tee -a	$LogFile	
	addToLog "jboss unzip status = $?"

	chown -fR jboss:jboss "$jbossHome"	| tee -a	$LogFile
	addToLog "jboss chown status = $?"

	addToLog "============================================================================"
	addToLog "list of $jbossDir 1st level directory"
	ls -ltr "$jbossDir"			| tee -a	$LogFile
	addToLog "============================================================================"

	addToLog "============================================================================"
	addToLog "list of $jbossDir bin directory"
	ls -ltr "$jbossDir/bin"			| tee -a	$LogFile
	addToLog "============================================================================"

	#	sudo su - jboss -c "id; bash $jbossDir/bin/add-user.sh"	| tee -a	$LogFile
	#	addToLog "jboss addusers status = $?"

	echo "jboss logic completed ..."	>>		$LogFile	2>&1
	addTimeToLog

cat<<HereDocEnd

# =========================================================================================================

JBoss installation completed

now login as jboss and execute :

        bash    jboss-as-7.1.1.Final/bin/add-user.sh


then execute :

	bash   *7.1*/bin/standalone.sh &


# =========================================================================================================

HereDocEnd


        turnOffDebugging
	return 0
}






centosLAMP()
{
	allowForDebugging

	sessionCore=centosLAMP
	sessionDesc="centos-based LAMP server"

	addToLog "setting up $sessionCore ($sessionDesc) support ..."
	addTimeToLog

	if [ $distro != "centos" ]; then
		return 49
	fi

	$UPDATE 2>&1 | tee -a                                   $LogFile

	for Pkg in httpd mariadb-server mariadb php php-mysql php-gd php-pear
		do
		$INSTALL        "$Pkg" 2>&1 | tee -a             $LogFile
		addToLog "pkg install status = $?"
		done
	#for

	$UPDATE 2>&1 | tee -a                                   $LogFile

	systemctl enable  httpd.service
	systemctl restart httpd.service
	systemctl status  httpd.service
	
	echo "<?php phpinfo(); ?>"			>	/var/www/html/info.php

	firewall-cmd	--permanent	--zone=public	--add-service=http 
	firewall-cmd	--permanent	--zone=public	--add-service=https
	firewall-cmd	--reload

	#	ufw allow proto tcp from 192.168.1.0/24 to any port mysql

	#	php -r 'echo "\n\nYour PHP installation is working fine.\n\n\n";'

	systemctl enable  mariadb.service
	systemctl restart mariadb.service
	systemctl status  mariadb.service
	
	addToLog "$sessionCore logic completed ..."
	addTimeToLog

	turnOffDebugging
	return 0
}




autoPlantSeeds()
{
	allowForDebugging

	sessionCore=autoPlantSeeds
	sessionDesc="automatically plant seeds"

	addToLog "setting up $sessionCore ($sessionDesc) support ..."
	addTimeToLog

	if [ $distro != "centos" ]; then
		return 47
	fi

	wget --output-document /var/www/html/index.html     192.168.1.57/seed.html
	wget --output-document /var/www/html/seed.php       192.168.1.57/seed.php

	chmod 744		/var/www/html/*.html
	chmod 755		/var/www/html/*.php

	wget --output-document /var/www/html/seed.exe       192.168.1.57/seed.exe
	chmod 755       /var/www/html/seed.exe

	wget --output-document /home/xt57/seed.sh           192.168.1.57/seed.sh
	chown root:root /home/xt57/seed.sh
	chmod 700       /home/xt57/seed.sh

	addToLog "$sessionCore logic completed ..."
	addTimeToLog

	turnOffDebugging
	return 0
}



autoNetConfig()
{
        allowForDebugging

        funName=netConfig

        addToLog "running $funName ..."
        addTimeToLog

        if [ $distro != "centos" ]; then
                addToLog "OS deemed to be other than centos ..."
                return
        fi

        #	echo "Enter hostname and final octet : \c"
        #	read s

	s="seed77,250"

        hostName=`echo ${s} | cut -f1 -d',' | tr -d ' '`
        finalOctet=`echo ${s} | cut -f2 -d',' | tr -d ' '`

        getNetInfo

        chkconfig --list        NetworkManager          >>      $LogFile        2>&1

        service                 NetworkManager  stop    >>      $LogFile        2>&1

        chkconfig               NetworkManager  off     >>      $LogFile        2>&1

        service                 network         start   >>      $LogFile        2>&1

        chkconfig               network         on      >>      $LogFile        2>&1

        ls -ltr /etc/sysconfig/network-scripts/         >>      $LogFile        2>&1

        netConfigPath="/etc/sysconfig/network-scripts/ifcfg-${gvNetDevice}"
        addToLog "netConfigPath = [ ${netConfigPath} ]"
        addTimeToLog

        netHostsPath="/etc/hosts"
        addToLog "netHostsPath = [ ${netHostsPath} ]"
        addTimeToLog

        netDnsPath="/etc/resolv.conf"
        addToLog "netDnsPath = [ ${netDnsPath} ]"
        addTimeToLog


#       populate the sysconfif ip setup file

sh -c "cat > ${netConfigPath}"<<EOF
TYPE=Ethernet
DEVICE=${gvNetDevice}
ONBOOT=yes
BOOTPROTO=none
IPADDR=192.168.1.${finalOctet}
GATEWAY=192.168.1.1
EOF




#       populate the hosts file

sh -c "cat > ${netHostsPath}"<<EOF
# supplied by xt57 logic
127.0.0.1       localhost
192.168.1.${finalOctet}   ${hostName}.xt57.net           ${hostName}
EOF




#       populate the rsolv.conf file

sh -c "cat > ${netDnsPath}"<<EOF
# supplied by xt57 logic
search xtdns.xt57.net xt57.net
nameserver 192.168.1.99
EOF


        service                 network         restart >>      $LogFile        2>&1

        ifconfig                                        >>      $LogFile        2>&1

        traceroute              www.google.com          >>      $LogFile        2>&1

        ifconfig -s 2>&1 | egrep -v "^Iface|^lo" | head -1

        ifconfig | grep "${finalOctet}"

        uname -a

        addToLog "$funName completed ..."
        addTimeToLog

        turnOffDebugging
        return 0
}



nagiosServer()
{
	allowForDebugging

	sessionCore=centosNagiosServer
	sessionDesc="centos-based Nagios server"

	addToLog "setting up $sessionCore ($sessionDesc) support ..."
	addTimeToLog

	if [ $distro != "centos" ]; then
		return 49
	fi

	useradd -m nagios				2>&1 	|	tee -a	$LogFile
	passwd nagios
	groupadd nagcmd					2>&1 	|	tee -a	$LogFile
	usermod -a -G nagcmd nagios		2>&1 	|	tee -a	$LogFile
	usermod -a -G nagcmd apache		2>&1 	|	tee -a	$LogFile

	$UPDATE 2>&1 | tee -a                               $LogFile

	for Pkg in gd gd-devel gcc glibc glibc-common
		do
		$INSTALL        "$Pkg" 2>&1 | tee -a            $LogFile
		addToLog "pkg install status = $?"
		done
	#for

	$UPDATE 2>&1 | tee -a                               $LogFile


	# this following code installs the nagios 
	ORIG_DIR="`pwd`"
		
	cd /tmp
	wget http://prdownloads.sourceforge.net/sourceforge/nagios/nagios-4.0.8.tar.gz
	tar xzf nagios-4.0.8.tar.gz						2>&1 | tee -a	$LogFile
	pwd												2>&1 | tee -a	$LogFile			
	ls -ltr 										2>&1 | tee -a	$LogFile	
	cd nagios-4.0.8
	pwd												2>&1 | tee -a	$LogFile			
	ls -ltr 										2>&1 | tee -a	$LogFile
	bash ./configure --with-command-group=nagcmd	2>&1 | tee -a	$LogFile
	make all										2>&1 | tee -a	$LogFile	
	make install									2>&1 | tee -a	$LogFile
	make install-init								2>&1 | tee -a	$LogFile
	make install-config								2>&1 | tee -a	$LogFile
	make install-commandmode						2>&1 | tee -a	$LogFile	
	make install-webconf							2>&1 | tee -a	$LogFile

	cd "$ORIG_PWD"

	htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

#	wget http://nagios-plugins.org/download/nagios-plugins-2.0.3.tar.gz

	systemctl restart httpd.service
	systemctl status  httpd.service

	# this following code installs the nagios plug-ins
	ORIG_DIR="`pwd`"
		
	cd /tmp
	wget http://nagios-plugins.org/download/nagios-plugins-2.0.3.tar.gz
	tar xzf nagios-plugins-2.0.3.tar.gz				2>&1 | tee -a	$LogFile
	pwd												2>&1 | tee -a	$LogFile			
	ls -ltr 										2>&1 | tee -a	$LogFile	
	cd nagios-plugins-2.0.3
	pwd												2>&1 | tee -a	$LogFile			
	ls -ltr 										2>&1 | tee -a	$LogFile
	bash ./configure --with-nagios-user=nagios --with-nagios-group=nagios		\
													2>&1 | tee -a	$LogFile
	make											2>&1 | tee -a	$LogFile	
	make install									2>&1 | tee -a	$LogFile

	cd "$ORIG_PWD"

	chkconfig --add nagios							2>&1 | tee -a	$LogFile
	chkconfig nagios on								2>&1 | tee -a	$LogFile
	systemctl restart nagios.service				2>&1 | tee -a	$LogFile
	systemctl status  nagios.service				2>&1 | tee -a	$LogFile

	addToLog "$sessionCore logic completed ..."
	addTimeToLog

	turnOffDebugging
	return 0
}








nagiosClient()
{
	allowForDebugging

	sessionCore=centosNagiosClient
	sessionDesc="centos-based Nagios client"

	addToLog "setting up $sessionCore ($sessionDesc) support ..."
	addTimeToLog

	if [ $distro != "centos" ]; then
		return 49
	fi

	$UPDATE 2>&1 | tee -a                               $LogFile

	for Pkg in epel-release
		do
		$INSTALL        "$Pkg" 2>&1 | tee -a            $LogFile
		addToLog "pkg install status = $?"
		done
	#for

	$UPDATE 2>&1 | tee -a                               $LogFile

	for Pkg in nrpe nagios-plugins-all
		do
		$INSTALL        "$Pkg" 2>&1 | tee -a            $LogFile
		addToLog "pkg install status = $?"
		done
	#for

	$UPDATE 2>&1 | tee -a                               $LogFile
	
	systemctl restart	nrpe.service
	systemctl enable	nrpe.service
	systemctl status	nrpe.service

	addToLog "$sessionCore logic completed ..."
	addTimeToLog

	turnOffDebugging
	return 0
}






centosCfeMaster()
{
	allowForDebugging

	sessionCore=centosCfeMaster
	sessionDesc="centos-based centosCoreConfigEnforcement"

	addToLog "setting up $sessionCore ($sessionDesc) support ..."
	addTimeToLog

	if [ $distro != "centos" ]; then
		return 49
	fi

	thirdOctet="$1"
	
	if [ "$thirdOctet" = "200" ]; then
		bCfServer="yes"
	else
		bCfServer="no"
	fi

	
	if [ "$thirdOctet" = "70" ]; then
		bPupServer="yes"
	else
		bPupServer="no"
	fi

	# $UPDATE 2>&1 | tee -a                               $LogFile


	# open port 5308 for cfengine server, port 8140 for puppet server
	if [ bCfServer = "yes" ]; then		# port = 5308
		Port=5308
	fi
	
	if [ bPupServer = "yes" ]; then		# port = 8140
		Port=8140
	fi
	
	#	if [ bCfServer = "yes" ] || [ bPupServer = "yes" ]; then
		firewall-cmd	--zone=public	--add-port=${Port}/tcp	\
						--permanent		2>&1 | tee -a	$LogFile	
		firewall-cmd   --reload			2>&1 | tee -a	$LogFile
#	fi	

	#
	RPM="cfengine-community-3.6.6-1.el7.x86_64.rpm"
	#wget 192.168.1.57/$RPM				2>&1 | tee -a	$Logfile
	stat=$?
	
	if [ $stat -ne 0 ]; then
		return 79
	fi

	#
	#rpm -i ./$RPM						2>&1 | tee -a	$Logfile
	stat=$?
	
	if [ $stat -ne 0 ]; then
		return 81
	fi

	# $UPDATE 2>&1 | tee -a                               $LogFile

#	stat=0
#	if [ bCfServer = "yes" ]; then
#		# automatic avahi bootstrapping looks like the following ...
#		/var/cfengine/bin/cf-serverd -A
#		stat=$?
#	fi
	
	if [ $stat -ne 0 ]; then
		return 82
	fi

	stat=0
#	if [ bCfServer = "yes" ]; then
#		# check automatic avahi bootstrapping status ...
#		avahi-browse -atr | grep cfenginehub > /dev/null 2>&1
#		stat=$?
#		if [ $stat -ne 0 ]; then
#			return 83
#		fi
#	fi
	
	#	manual bootstrap would look like the following ...
	myPgm=/var/cfengine/bin/cf-agent
	"$myPgm" --bootstrap 192.168.1.200  2>&1 | tee -a	$Logfile
	stat=$?
	
	# automatic avahi bootstrapping looks like the following ...
	# /var/cfengine/bin/cf-agent -B :avahi 2>&1 | tee -a	$LogFile	
	# stat=$?
			
	if [ $stat -ne 0 ]; then
		return 83
	fi

	Service=cfengine3.service
	for Action in enable restart status
		do
		# systemctl $Action $Service		2>&1 | tee -a	$LogFile
		addToLog "action status = $?"
		done
	#for


	#
	RPM="puppetlabs-release-el-7.noarch.rpm"	
	wget 192.168.1.57/$RPM			2>&1 | tee -a		$Logfile
	stat=$?
	
	if [ $stat -ne 0 ]; then
		return 79
	fi

	#
	#rpm -i ./$RPM					2>&1 | tee -a		$Logfile
	stat=$?
	
	if [ $stat -ne 0 ]; then
		return 81
	fi




	#
	RPM="puppetlabs-release-pc1-el-7.noarch.rpm"
	wget 192.168.1.57/$RPM			2>&1 | tee -a		$Logfile
	stat=$?
	
	if [ $stat -ne 0 ]; then
		return 79
	fi

	#	
	#rpm -i ./$RPM					2>&1 | tee -a		$Logfile
	stat=$?
	
	if [ $stat -ne 0 ]; then
		return 81
	fi

	rm -r *.rpm 					2>&1 | tee -a		$Logfile


	$UPDATE 2>&1 | tee -a                               $LogFile


	# probably relagating this install to cfengine and puppet
	for Pkg in   epel-release     #  avahi avahi-libs  # already in Cent7 
		do
		$INSTALL        "$Pkg" 2>&1 | tee -a            $LogFile
		addToLog "pkg install status = $?"
		# continue
		done
	#for

	$UPDATE 2>&1 | tee -a                               $LogFile


	addToLog "$sessionCore logic completed ..."
	addTimeToLog

	turnOffDebugging
	return 0
}





















centosPuppetMaster()
{
	allowForDebugging

	sessionCore=centosPuppetServer
	sessionDesc="setup CentOS-based Puppet Server"

	addToLog "setting up $sessionCore ($sessionDesc) support ..."
	addTimeToLog

	if [ $distro != "centos" ]; then
		return 49
	fi


	# open port 8140 for puppet-server support
	Port=8140
	
	firewall-cmd	--zone=public	--add-port=${Port}/tcp	\
					--permanent		2>&1 | tee -a		$LogFile	
	firewall-cmd   --reload			2>&1 | tee -a		$LogFile	


	#	ensure the new server is listening on our selected port
	netstat -nlp | grep ${Port}		2>&1 | tee -a		$LogFile	
	lsof  -i tcp:${Port}			2>&1 | tee -a		$LogFile	


	for Pkg in puppet-server
		do
		$INSTALL        "$Pkg" 		2>&1 | tee -a		$LogFile
		addToLog "pkg install status = $?"
		done
	#for

	$UPDATE 2>&1 | tee -a                             	$LogFile


	# fetch the list of files to be processed
	FilesList="centos-7-puppetmaster-install.xt57list"

	wget "192.168.1.57/$FilesList"		2>&1 | tee -a		$Logfile
			
	stat=$?
	
	if [ $stat -ne 0 ]; then
		return 79
	fi
			



	# fetch and configure the new puppet server definition files
	cat $FilesList |
		while read DefString
			do
			Src=`echo $DefString| tr -d ' '| tr -d '\t'|  cut -f1 -d'|'`
			Dst=`echo $DefString| tr -d ' '| tr -d '\t'|  cut -f2 -d'|'`
			
			wget -O "$Dst" "192.168.1.57/$Src"				\
										2>&1 | tee -a		$Logfile
			
			stat=$?
	
			if [ $stat -ne 0 ]; then
				return 79
			fi
			
			chmod 644 ${Dst}			2>&1 | tee -a		$Logfile
			# rm ${Src}					2>&1 | tee -a		$Logfile
			done
		#while
	#cat
	rm ${FilesList}						2>&1 | tee -a		$Logfile

	Service=puppetmaster.service
	for Action in enable restart status
		do
		systemctl $Action ${Service}	2>&1 | tee -a	$LogFile
		addToLog "action status = $?"
		done
	#for

	# ensure the master is always running
	puppet resource service puppetmaster ensure=running enable=true	\
									2>&1 | tee -a		$LogFile	

	stat=0
	
	if [ $stat -ne 0 ]; then
		return 83
	fi

#	ensure we have the latest puppet release
	puppet resource package puppet-server ensure=latest	\
									2>&1 | tee -a		$LogFile	



	addToLog "$sessionCore logic completed ..."
	addTimeToLog

	turnOffDebugging
	return 0
}






mubuPuppetMaster()
{
	allowForDebugging

	sessionCore=mubuPuppetServer
	sessionDesc="setup Mubu-based Puppet Server"

	addToLog "setting up $sessionCore ($sessionDesc) support ..."
	addTimeToLog

	if [ $distro != "mubu" ]; then
		return 49
	fi


	# open port 8140 for puppet-server support
	Port=8140
	
	
	ufw enable						2>&1 | tee -a		$LogFile	
	ufw allow	from	192.168.1.0/24					\
				to		any				port ${Port}	\
									2>&1 | tee -a		$LogFile	
	ufw status						2>&1 | tee -a		$LogFile	


	#	ensure the new server is listening on our selected port
	netstat -nlp | grep ${Port}		2>&1 | tee -a		$LogFile	
	lsof  -i tcp:${Port}			2>&1 | tee -a		$LogFile	


	for Pkg in puppet-server
		do
		$INSTALL        "$Pkg" 		2>&1 | tee -a		$LogFile
		addToLog "pkg install status = $?"
		done
	#for

	$UPDATE 2>&1 | tee -a                             	$LogFile


	# fetch the list of files to be processed
	FilesList="centos-7-puppetmaster-install.xt57list"

	wget "192.168.1.57/$FilesList"		2>&1 | tee -a		$Logfile
			
	stat=$?
	
	if [ $stat -ne 0 ]; then
		return 79
	fi
			



	# fetch and configure the new puppet server definition files
	cat $FilesList |
		while read DefString
			do
			Src=`echo $DefString| tr -d ' '| tr -d '\t'|  cut -f1 -d'|'`
			Dst=`echo $DefString| tr -d ' '| tr -d '\t'|  cut -f2 -d'|'`
			
			wget -O "$Dst" "192.168.1.57/$Src"				\
										2>&1 | tee -a		$Logfile
			
			stat=$?
	
			if [ $stat -ne 0 ]; then
				return 79
			fi
			
			chmod 644 ${Dst}			2>&1 | tee -a		$Logfile
			# rm ${Src}					2>&1 | tee -a		$Logfile
			done
		#while
	#cat
	rm ${FilesList}						2>&1 | tee -a		$Logfile

	Service=puppetmaster.service
	for Action in enable restart status
		do
		systemctl $Action ${Service}	2>&1 | tee -a	$LogFile
		addToLog "action status = $?"
		done
	#for

	# ensure the master is always running
	puppet resource service puppetmaster ensure=running enable=true	\
									2>&1 | tee -a		$LogFile	

	stat=0
	
	if [ $stat -ne 0 ]; then
		return 83
	fi

#	ensure we have the latest puppet release
	puppet resource package puppet-server ensure=latest	\
									2>&1 | tee -a		$LogFile	



	addToLog "$sessionCore logic completed ..."
	addTimeToLog

	turnOffDebugging
	return 0
}












centosPuppetAgent()
{
	allowForDebugging

	sessionCore=centosPuppetAgent
	sessionDesc="setup CentOS-based Puppet Agent"

	addToLog "setting up $sessionCore ($sessionDesc) support ..."
	addTimeToLog

	if [ $distro != "centos" ]; then
		return 49
	fi

	for Pkg in puppet
		do
		$INSTALL        "$Pkg" 2>&1 | tee -a            $LogFile
		addToLog "pkg install status = $?"
		done
	#for









	# fetch the list of files to be processed
	FilesList="centos-7-puppetagent-install.xt57list"

	wget "192.168.1.57/$FilesList"		2>&1 | tee -a		$Logfile
			
	stat=$?
	
	if [ $stat -ne 0 ]; then
		return 79
	fi
			



	# fetch and configure the new puppet server definition files
	cat $FilesList |
		while read DefString
			do
			Src=`echo $DefString| tr -d ' '| tr -d '\t'|  cut -f1 -d'|'`
			Dst=`echo $DefString| tr -d ' '| tr -d '\t'|  cut -f2 -d'|'`
			
			wget -O "$Dst" "192.168.1.57/$Src"				\
										2>&1 | tee -a		$Logfile
			
			stat=$?
	
			if [ $stat -ne 0 ]; then
				return 79
			fi
			
			chmod 644 ${Dst}			2>&1 | tee -a		$Logfile
			# rm ${Src}					2>&1 | tee -a		$Logfile
			done
		#while
	#cat
	rm ${FilesList}						2>&1 | tee -a		$Logfile






	for Action in enable restart status
		do
		systemctl $Action puppet 2>&1 | tee -a			$LogFile
		addToLog "action status = $?"
		done
	#for

	# ensure the agent runs as a daemon
	puppet agent --daemonize


	# ensure the master is always running
	puppet resource service puppet ensure=running enable=true	\
									>&1 | tee -a		$LogFile	

	stat=0
	
	if [ $stat -ne 0 ]; then
		return 83
	fi


#	ensure we have the latest puppet release
	puppet resource package puppet ensure=latest	\
									2>&1 | tee -a		$LogFile	


#	test connection to the puppet server
	puppet agent --server puppet.xt57.net --waitforcert 30 --test

#	sign all pending certificates
	puppet cert sign --all



#┌───────────────┬───────────────────┐
#│ Pre-2.6       │ Post-2.6          │
#├───────────────┼───────────────────┤
#│ puppetmasterd │ puppet master     │
#│ puppetd       │ puppet agent      │
#│ puppet        │ puppet apply      │
#│ puppetca      │ puppet cert       │
#│ ralsh         │ puppet resource   │
#│ puppetrun     │ puppet kick       │
#│ puppetqd      │ puppet queue      │
#│ filebucket    │ puppet filebucket │
#│ puppetdoc     │ puppet doc        │
#│ pi            │ puppet describe   │
#└───────────────┴───────────────────┘


	addToLog "$sessionCore logic completed ..."
	addTimeToLog

	turnOffDebugging
	return 0
}







centosBind()
{
	allowForDebugging

	sessionCore=centosBind
	sessionDesc="centos-based Bind server"

	addToLog "setting up $sessionCore ($sessionDesc) support ..."
	addTimeToLog

	if [ $distro != "centos" ]; then
		return 49
	fi


	# open port 53 for bind support
	firewall-cmd	--add-port=53/tcp --permanent		\
									2>&1 | tee -a		$LogFile
	
	firewall-cmd	--add-port=53/udp --permanent		\
									2>&1 | tee -a		$LogFile
					
	firewall-cmd	--reload		2>&1 | tee -a		$LogFile	



	$UPDATE 2>&1 | tee -a                               $LogFile


	for Pkg in    bind   bind-utils
		do
		$INSTALL        "$Pkg" 2>&1 | tee -a            $LogFile
		addToLog "pkg install status = $?"
		done
	#for

	$UPDATE 2>&1 | tee -a                               $LogFile


	# place each config file in its proper location
	for xPath in    named.conf  forward.xt57  reverse.xt57
		do
		#	fetch the master copy of each of these files
		Src="192.168.1.57/centos-7-${xPath}"
		echo "$Src" | grep -i "named\.conf"	> /dev/null 2>&1
		if [ $? -eq 0 ]; then
			Dst="/etc/named.conf"
		else
			Dst="/var/named/${xPath}"			
		fi
		wget -O "$Dst" "$Src"		2>&1 | tee -a		$Logfile
		stat=$?
	
		if [ $stat -ne 0 ]; then
			return 79
		fi
		
		done
	#for


	# normalize the ownership and permissions of our files
	chgrp named -R /var/named		2>&1 | tee -a		$Logfile
	
	chown -v root:named									\
			/etc/named.conf			2>&1 | tee -a		$Logfile
			
	restorecon -rv /var/named		2>&1 | tee -a		$Logfile
	
	restorecon /etc/named.conf		2>&1 | tee -a		$Logfile


	# enable and bring-up DNS service
	for Action in enable restart status
		do
		systemctl $Action named.service 2>&1 | tee -a	$LogFile
		addToLog "action status = $?"
		done
	#for


	# restart network services
	for Action in restart status
		do
		systemctl $Action NetworkManager.service		\
									2>&1 | tee -a		$LogFile
		addToLog "action status = $?"
		done
	#for


	# normalize the ownership and permissions of our files
	#named-checkconf		xt57.net						\
	#					/var/named/forward.xt57	
	named-checkconf					2>&1 | tee -a		$Logfile
	

	named-checkzone		xt57.net						\
						/var/named/forward.xt57			\
										2>&1 | tee -a	$Logfile
	
	
	named-checkzone		xt57.net						\
						/var/named/reverse.xt57			\
										2>&1 | tee -a	$Logfile
	
	dig xtdns.xt57.net					2>&1 | tee -a	$Logfile

	nslookup 192.168.1.57				2>&1 | tee -a	$Logfile

	nslookup 192.168.1.200				2>&1 | tee -a	$Logfile


	addToLog "$sessionCore logic completed ..."
	addTimeToLog

	turnOffDebugging
	return 0
}









nmNetwork()
{
	allowForDebugging

	sessionCore=nmNetwork
	sessionDesc="$sessionCore"

	addToLog "setting up $sessionCore ($sessionDesc) support ..."
	addTimeToLog

	if [ $distro != "centos" ]; then
		return 49
	fi

	third="$1"
	
	$UPDATE 2>&1 | tee -a                               $LogFile

	while [ `nmcli --fields UUID connection show | wc -l | tr -d '\n'` -gt 1 ]
		do
		uuid=`nmcli --fields UUID connection show | grep -v UUID | head -1 | tr -d ' '`
		echo "uuid for deletion = <$uuid>"				| tee -a $LogFile
		nmcli connection delete uuid "$uuid" 2>&1		| tee -a $LogFile
		done
	
	dev=enp0s3
		
	nmcli connection add type ethernet con-name $dev ifname $dev ip4 192.168.1.$third gw4 192.168.1.1
	nmcli connection modify $dev ipv4.dns "192.168.1.99 8.8.8.8"

	ifconfig | grep -i "inet " | grep -v "127.0.0.1"	| tee -a $LogFile


	if [ $third != "99" ]; then
		setupCentosCoreConfigEnforcement "$1"
	fi
	
	addToLog "$sessionCore logic completed ..."
	addTimeToLog

	turnOffDebugging
	return 0
}





centosCoreConfigEnforcement()
{
	allowForDebugging

	sessionCore=centosCoreConfigEnforcement
	sessionDesc="centos-based setupCentosCoreConfigEnforcement"

	addToLog "setting up $sessionCore ($sessionDesc) support ..."
	addTimeToLog

	if [ $distro != "centos" ]; then
		return 49
	fi

	thirdOctet="$1"
	
	# ensure that packages are updated
	$UPDATE 2>&1 | tee -a                               $LogFile





	# install the puppet repos package
	RPM="puppetlabs-release-el-7.noarch.rpm"	
	wget 192.168.1.57/$RPM			2>&1 | tee -a		$Logfile
	stat=$?
	
	if [ $stat -ne 0 ]; then
		return 79
	fi

	#
	rpm -i ./$RPM					2>&1 | tee -a		$Logfile
	stat=$?
	
	if [ $stat -ne 0 ]; then
		return 81
	fi

#	clean-up any rpms we downloaded
	rm -r *.rpm 					2>&1 | tee -a		$Logfile



#	setup cfeMaster, if this is it
	if [ "$thirdOctet" = "200" ]; then
		setupCfeMaster
	fi

#	ensure the correct puppet package is installed	
	if [ "$thirdOctet" = "70" ]; then
		setupCentosPuppetMaster
	else
		setupCentosPuppetAgent
	fi



	$UPDATE 2>&1 | tee -a                               $LogFile

	# probably relagating this install to cfengine and puppet
	for Pkg in   epel-release     #  avahi avahi-libs  # already in Cent7 
		do
		$INSTALL        "$Pkg" 2>&1 | tee -a            $LogFile
		addToLog "pkg install status = $?"
		#	continue
		done
	#for

	$UPDATE 2>&1 | tee -a                               $LogFile


	addToLog "$sessionCore logic completed ..."
	addTimeToLog

	turnOffDebugging
	return 0
}




mintJDK-Old()
{
	allowForDebugging

	sessionCore=mintJDK
	sessionDesc="mintJDK"

	addToLog "setting up $sessionCore ($sessionDesc) support ..."
	addTimeToLog

	if [ $extDistro != "mubu" ]; then
		return 83
	fi
	
        addToLog "================="

	pkgListCmd="dpkg --get-selections"
	pkgInstQualifier="grep -v deinstall"

        addToLog "================="
        addToLog "these JREs and JDKs exist before the JDK install ..."
	$pkgListCmd 2>&1 | $pkgInstQualifier | grep -iE "jre|jdk" | cut -f1 -d':'	| tee -a 	$LogFile
        addToLog "================="

        addToLog "removing existing jdk and jre instances ..."
	$pkgListCmd 2>/dev/null | $pkgInstQualifier | grep -iE "jre|jdk" | cut -f1 -d':' |
		while read pkg
			do
        		addToLog "removing $pkg"
			apt-get -y remove "$pkg"  2>&1			| tee -a	$LogFile
		done
	#endpipe

        addToLog "================="
        addToLog "these JDKs and JREs exist after removal effort ..."
	$pkgListCmd 2>&1 | $pkgInstQualifier | grep -iE "jre|jdk" | cut -f1 -d':'	| tee -a 	$LogFile
        addToLog "================="

        addToLog "setup the new jdk home"
	usrHome=/home/iansblues
	jdkBase=opt.d/jdk.d
	rm -rf		$usrHome/$jdkBase
	mkdir -p	$usrHome/$jdkBase

	mkdir -p	/tmp/jdk.$$
	cd		/tmp/jdk.$$ 

	pkgSrc="jdk-production.tar.gz"
	wget		192.168.1.57/$pkgSrc

	tar xvfz	$pkgSrc		>	/dev/null	2>&1
	rm -f	 	$pkgSrc

	ls -ltr 

	pkg=ls | grep -i jdk | head -1
        addToLog "new formal JDK name = $pkg"
	cd $pkg

	ls -ltr 

	pwd
	basename pwd	>	officialName.txt

	cp -rp *		$usrHome/$jdkBase
		
	cd $usrHome

	export JAVA_HOME="/home/iansblues/opt.d/jdk.d"
	#	export PATH="$PATH:$JAVA_HOME/bin"

sh -c "cat >> $usrHome/.bashrc "<<EOF

	export CLASSPATH="."

	export JAVA_HOME="/home/iansblues/opt.d/jdk.d"

	export JRE_HOME="$JAVA_HOME/jre"
	export JAVA_BINDIR="$JAVA_HOME/bin"
	export JDK_HOME="$JAVA_HOME"
	export SDK_HOME="$JAVA_HOME"
	export JAVA_ROOT="$JAVA_HOME"

	export PATH="$PATH:$JAVA_HOME/bin"

	HISTSIZE=30000
	HISTFILESIZE=30000

EOF

        source $usrHome/.bashrc           #       load into current shell


sh -c "cat >> /etc/environment "<<EOF

	export CLASSPATH="."

	export JAVA_HOME="/home/iansblues/opt.d/jdk.d"

	export JRE_HOME="$JAVA_HOME/jre"
	export JAVA_BINDIR="$JAVA_HOME/bin"
	export JDK_HOME="$JAVA_HOME"
	export SDK_HOME="$JAVA_HOME"
	export JAVA_ROOT="$JAVA_HOME"

	export PATH="$PATH:$JAVA_HOME/bin"

	HISTSIZE=30000
	HISTFILESIZE=30000

EOF

        source /etc/environment        #       load into current shell

        addToLog "================="
        addToLog "java runtime version check"
        java -version 2>&1                                              | tee -a        $LogFile

        addToLog "java compiler version check"
        javac -version 2>&1                                             | tee -a        $LogFile

	turnOffDebugging
	return 0
}



removeExistingMintJDKs()
{
        allowForDebugging

        sessionCore=removeMintJDKs
        sessionDesc=removeMintJDKs

        addToLog "setting up $sessionCore ($sessionDesc) support ..."
        addTimeToLog

        if [ $extDistro != "mubu" ]; then
                return 83
        fi


        #       remove existing JDKs
        #       =====================


        pkgListCmd="dpkg --get-selections"
        pkgInstQualifier="grep -v deinstall"

        addToLog "================="
        addToLog "these JREs and JDKs exist before the JDK install ..."
        $pkgListCmd 2>&1 | $pkgInstQualifier | grep -iE "jre|jdk" | cut -f1 -d':'       | tee -a        $LogFile
        addToLog "================="

        addToLog "removing existing jdk and jre instances ..."
        $pkgListCmd 2>/dev/null | $pkgInstQualifier | grep -iE "jre|jdk" | cut -f1 -d':' |
                while read pkg
                        do
                        addToLog "removing $pkg"
                        apt-get -y remove "$pkg"  2>&1                  | tee -a        $LogFile
                done
        #endpipe

        addToLog "================="
        addToLog "these JDKs and JREs exist after the removal effort ..."
        $pkgListCmd 2>&1 | $pkgInstQualifier | grep -iE "jre|jdk" | cut -f1 -d':'       | tee -a        $LogFile
        addToLog "================="

	turnOffDebugging
	return 0
}


stringLengthExampleSyntax()
{
	# example of string length test in bash
	#if [ ${#variable} -gt 0 ]; then

	return 0
}





hidingThisCodeForUseAboveInFileRelatedOption()
{
	if !	buildTransportUrl; then
		post "URL build failure"; exit 204
	fi
		
	
	usrHome=/home/$coreAcct
	jdkBase=opt.d/jdk.d
	rm -rf		$usrHome/$jdkBase
	mkdir -p	$usrHome/$jdkBase

	mkdir -p	/tmp/jdk.$$
	cd		/tmp/jdk.$$ 

	pkgSrc="$pkgTransportUrl/jdk-production.tar.gz"
	wget		"$pkgTransportUrl/jdk-production.tar.gz"

	tar xvfz	$pkgSrc		>	/dev/null	2>&1
	rm -f	 	$pkgSrc

	ls -ltr 

	pkg=ls | grep -i jdk | head -1
        addToLog "new formal JDK name = $pkg"
	cd $pkg

	ls -ltr 

	pwd
	basename pwd	>	officialName.txt

	cp -rp *		$usrHome/$jdkBase
		
	cd $usrHome

	return 0
}



eclipse()
{
        allowForDebugging

        sessionCore=eclipse
        sessionDesc="setupEclipse"

        addTimeToLog

        if [ $distro != "suse" ]; then
                return 83
        fi


        addToLog "================="
        addToLog "adding eclipse"
        #	AnchorDir="pwd"

        mkdir   -p      /home/iansblues/opt.d                           > /dev/null     2>&1
        cd              /home/iansblues/opt.d                           > /dev/null     2>&1
        wget    -O      /home/iansblues/opt.d/eclipse-4.5.0.zip         192.168.1.57/eclipse-4.5.0.zip  \
                                                                        | tee -a        $LogFile
        unzip           /home/iansblues/opt.d/eclipse-4.5.0.zip         | tee -a        $LogFile
        cd              "$AnchorDir"                                    | tee -a        $LogFile


        addToLog "need SceneBuilder support here"
        #mkdir   -p      /home/iansblues/jars.d                          > /dev/null     2>&1
        #wget    -O      /home/iansblues/jars.d/SceneBuilder-8.0.0.jar  192.168.1.57/SceneBuilder-8.0.0.jar  \
        #  


        turnOffDebugging
        return 0
}



netbeans()
{
        allowForDebugging

        sessionCore=netbeans
        sessionDesc="setupNetbeans"

        addTimeToLog

        addToLog "setup the new netbeans home"

			usrHome=/home/iansblues
			netbeansBase=opt.d/netbeans.d
	rm -rf		$usrHome/$netbeansBase
	mkdir -p	$usrHome/$netbeansBase

	mkdir -p	/tmp/netbeans.$$
	cd		/tmp/netbeans.$$ 

	pkgSrc="netbeans-production.sh"
	wget		192.168.1.57/$pkgSrc	> /dev/null 2>&1			| tee -a        $LogFile

        source /etc/environment        #       load into current shell

	java -version
	javac -version

	env | grep -iE "java|jre|jdk"

	bash /tmp/netbeans.$$/$pkgSrc		2>&1			| tee -a	$LogFile

        turnOffDebugging
        return 0
}






centosJDK()
{
        allowForDebugging

        sessionCore=centosJDK
        sessionDesc="setupCentosJDK"

        addTimeToLog

        if [ $distro != "centos" ]; then
                return 83
        fi

        addToLog "these JREs exist before the JDK install ..."
	rpm -qa | grep -E '^open[jre|jdk]|j[re|dk]'			| tee -a 	$LogFile

        addToLog "removing existing openjdk instances ..."
	yum -y list | egrep -i "jdk|jre" | cut -f1 -d' ' | while read pkg
		do	
        	addToLog "removing $pkg, if it still exists ..."
		yum -y remove "$pkg"					| tee -a	$LogFile
	done

        addToLog "these JDKs and JREs exist after removing original packages ..."
	yum -y list | egrep -i "jdk|jre" | cut -f1 -d' ' 

        addToLog "downloading the JDK from homebase ..."
	pkg="jdk-8u65-linux-x64.rpm"
	wget	-O	/home/iansblues/$pkg	 192.168.1.57/$pkg

        addToLog "installing Oracles JDK ..."
	rpm -ivh /home/iansblues/$pkg  	2>&1				| tee -a        $LogFile

        addToLog "java runtime version check"
        java -version                                                   | tee -a        $LogFile

        addToLog "java compiler version check"
        javac -version                                                  | tee -a        $LogFile


        # echo "$jPath"

        # cat /etc/environment

        #       grep JAVA_HOME /etc/environment                 >       /dev/null               2>&1
        #       if [ $? -gt 0 ]; then
        #               echo                                                    >>      /etc/environment        2>&1
        #               echo "JAVA_HOME=${jPath}"               >>      /etc/environment        2>&1
        #               echo                                                    >>      /etc/environment        2>&1
        #       fi

        # source /etc/environment               #       load into current shell

        turnOffDebugging
        return 0
}







mintNetbeans()
{
	allowForDebugging

	sessionCore=mubuNetbeans
	sessionDesc="setupMubuNetbeans"

	addTimeToLog

	if [ $extDistro != "mubu" ]; then
		return 83
	fi
	
	InstallFile=netbeans-8.0.2-javase-linux.sh
	
	rm -rf		/home/iansblues/netbeans*javase*.sh
	
	wget -O		/home/iansblues/$InstallFile		\
				192.168.1.57/$InstallFile	| tee -a	$LogFile	
	
	bash -x /home/iansblues/netbeans*javase*.sh

	turnOffDebugging
	return 0
}




mintMono()
{
	allowForDebugging

	sessionCore=setupMintMono
	sessionDesc="setupMintMono"

	addTimeToLog

	if [ $extDistro != "mubu" ]; then
		return 83
	fi
	
	rm /etc/apt/sources.list.d/mono-xamarin*	 	2>&1 | tee -a	$LogFile
	
	Srvr="hkp://keyserver.ubuntu.com:80"
	RcvKeys="3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF"
		
	apt-key adv --keyserver "$Srvr"					\
				--recv-keys "$RcvKeys"				2>&1 | tee -a	$LogFile	
	
	SrcsEntry="deb http://download.mono-project.com/repo/debian wheezy main"
	SrcsList="/etc/apt/sources.list.d/mono-xamarin.list"
	echo "$SrcsEntry"  >> "$SrcsList"				2>				$LogFile
	
	$UPDATE 2>&1 | tee -a                               $LogFile

	for pkg in  mono-complete  monodevelop    # libmono-cairo2.0-cil
		do
		$INSTALL        "$pkg" 2>&1 | tee -a            $LogFile
		addToLog "pkg install status = $?"
		done
	#for



	turnOffDebugging
	return 0
}



mintJDK_previous()
{
        allowForDebugging

        sessionCore=mintJDK
        sessionDesc="setup Mint JDK"

        addToLog "setting up $sessionCore ($sessionDesc) support ..."
        addTimeToLog

        if [ $extDistro != "mubu" ]; then
                return 83
        fi

        #       call for the removal of all current JDKs
        removeExistingMintJDKs

        #       setup the new jdk
        #       =================

        post "setup the new JDK"

        #       web update approach goes here
        
        #       file-based pkg execution goes here


        #       populate the required env vars
        #       ==============================
        envFile=jdkEnvVars.sh
        >                       ~/.jdkEnvVars.sh                | tee -a        $LogFile
        chmod 655               ~/.jdkEnvVars.sh                | tee -a        $LogFile
        chmod ${coreAcct}       ~/.jdkEnvVars.sh                | tee -a        $LogFile
        ls -ltr                 ~/.jdkEnvVars.sh                | tee -a        $LogFile

sh -c "cat > ~/.jdkEnvVars.sh "<<EOF

        export CLASSPATH="."

        export JAVA_HOME="/home/$coreAcct/opt.d/jdk.d"

        export JRE_HOME="$JAVA_HOME/jre"
        export JAVA_BINDIR="$JAVA_HOME/bin"
        export JDK_HOME="$JAVA_HOME"
        export SDK_HOME="$JAVA_HOME"
        export JAVA_ROOT="$JAVA_HOME"

        export PATH="$PATH:$JAVA_HOME/bin"
EOF
        #       chown   $coreAcct       ~/.jdkEnvVars.sh
        #       chmod   +x              ~/.jdkEnvVars.sh

        source                          ~/.jdkEnvVars.sh          #       load into current shell env


        addToLog "================="
        addToLog "java runtime version check"
        java -version 2>&1                                              | tee -a        $LogFile

        addToLog "java compiler version check"
        javac -version 2>&1                                             | tee -a        $LogFile


        turnOffDebugging
        return 0
}


bWeAreVirtualized()
{
	allowForDebugging

    lspci 2>&1 | grep -i virtualbox > /dev/null 2>&1
    
    if [ $? -gt 0 ]; then
        turnOffDebugging
		return 1
    fi

	turnOffDebugging
	return 0
}


supportVirtualBox()
{
    allowForDebugging

    sessionCore=guestAdditions
        
    post "setting-up VirtualBox Guest Additions"
    addTimeToLog    

    if ! bWeAreVirtualized; then
    	post "this is not a VirtualBox environment, skipping logic <return>"
    	return 0
    fi

    post; post
    post "mount the Guest Additions media now (Menu->Devices->Insert)"
    post "press <return>"
    post; post
    read x
        
    mount 2>&1 | grep -i additions > /dev/null 2>&1
    if [ $? -gt 0 ]; then
        post "Guest Additions media not yet available - exit 243 <return>"
        read x
        return 243
    fi

    gaDir="`mount | grep -i additions 2>&1 | cut -f3 -d' '`"
    
    if ! file $gaDir/*.run /dev/null 2>&1; then
        post "Guest Additions run script not available - exit 244 <return>"
        read x
        return 244
    fi
    
    post "now executing Guest Additions installation <please wait>"  
    
    if ! bash $gaDir/*.run; then
        post "Guest Additions run script failed - exit 245 <return>"
        read x
        return 245
    fi
    
	post "updating vbox group memberships ..."
	groupadd vboxusers	        2>&1 | tee -a $LogFile	
	groupadd vboxsf		        2>&1 | tee -a $LogFile	

	for acct in $coreAcct di07zd4 iansblues xt57 kim
		do
		if id $acct > /dev/null 2>&1; then
			post "adding $acct to vboxusers users group ..."
			usermod -a -G vboxusers	$acct	2>&1 | tee -a $LogFile	
	
			post "adding $acct to vboxsf shared files group ..."
			usermod -a -G vboxsf	$acct	2>&1 | tee -a $LogFile	
		fi
	done
    
    post "VirtualBox now fully supported <return>"; read x

    turnOffDebugging
    return 0
}


JDK()
{
    allowForDebugging

    sessionCore=JDK

    Post "setting up $sessionCore support ..."
    addTimeToLog
        
    targetVersion="1.8."

    javac -version 2>&1 | grep '1\.8\.' /dev/null 2>&1
    if [ $? -eq 0 ]; then
        post "JDK $targetVersion already installed - exit 245"
        javac -version
        read x
        return 245
    fi
        
    if [ $distro != "ubuntu" ]; then
        post "Linux distro is not ubuntu; JDK withheld - exit 246"
        read x       
        return 246
    fi

    post "were are ready to install over the web"
        
    if ! grep -i webupd /etc/apt/sources.list > /dev/null 2>&1; then
        if ! add-apt-repository ppa:webupd8team/java; then
            return 21
        fi
    fi
        
    apt-get -y update >> $webUpdLogFile 2>&1
        
    if ! apt-get -y install oracle-java8-installer; then
        post "JDK install failed - exit 213"; read x
        return 213
    fi
        
    if ! apt-get -y install oracle-java8-set-default; then
        post "JDK env post failed - exit 214"; read x
        return 214
    fi

    post "java runtime version check"
    java -version 2>&1                                              | tee -a        $LogFile

    post "java compiler version check"
    javac -version 2>&1                                             | tee -a        $LogFile

    turnOffDebugging
    return 0
}




usefulCodeFragments()
{
	ifconfig | grep "192.168.1.[0-9][0-9]."	> /dev/null 2>&1

	wget -O /home/iansblues/jdk_ee.sh          192.168.1.57/java_ee_sdk-6u3-jdk7-linux-x64.sh

	# example of string length test in bash
	#if [ ${#variable} -gt 0 ]; then

	return 0
}


quit()
{
    post "exiting ..."
	exit 0
}



cull()
{
	. ./cull.sh
    return $?
}



listPackages()
{
    post "listing installed packages ..."

    aptitude search '~i!~M'         # list all installed packages

    post "listing completed <return>"; read x
    
    return $?
}



draw()
{
    post "draw session underway ..."

	for name in     cull.sh             \
	                cull-lubuntu.cfg    \
	                weave.jpg
	    do
        rm ./$name                  >   /dev/null   2>&1
        rm ./$name.1                >   /dev/null   2>&1     	
        rm ./$name.2                >   /dev/null   2>&1
        rm ./$name.3                >   /dev/null   2>&1

	    wget    xt57.net/$name
	    
	    post "new $name file has checksum of : `sum ./$name | cut -f1 -d':'`"
    	done
    #for
	
    post "wget draws completed <return>"; read x	
	
	return 0

}



installAptitude()
{

    #   aptitude search '~i!~M'          return only currently-installed packages 

    post "installing aptitude ..."

    if ! apt-get -y install aptitude 2>&1 | tee -a $LogFile; then
        post "could not install aptitude - exit 242"
        exit 242
    fi
    post "aptitude installed <return>"; read x
    return 0
}

 
addCoreAccounts()
{
        allowForDebugging

        sessionCore=ensureCoreAccounts
        sessionDesc="ensure we have core accoutns for home base operations"

        post "setting up $sessionCore ($sessionDesc) support ..."
        postTime

	for acct in coreAcct xt57 di07zd4 iansblues kim
		do
		if id $acct > /dev/null 2>&1; then
			continue
		else
			adduser $acct			| tee -a	$LogFile
			post "<$acct> adduser status = $?"
		fi
	done

        post "$sessionCore logic completed ..."
        postTime

        turnOffDebugging
        return 0
}




#	begin execution here


#	begin execution here
#	====================
#

    distro=ubuntu
	if ! `echo "$distro" | grep -i "ubuntu"`; then
		post "not expected"
        exit 1
	fi

    post "as expected"
    exit 0





	touchLog
	allowForDebugging

	ensureCoreAccounts

	addToLog "current distro is $distro"
	addToLog "extended distro is $extDistro"

	if [ "$1" = "netsetup" ]; then
		addToLog "running netsetup function, before main logic ..."
		addTimeToLog
		autoNetConfig
		autoNetConfig
		exit 0
	fi
			

	# vet arg #1 as possible 3rd octet of an IP address
	isNumeric=no
	echo "$1" | grep '^[0-9]\{1,3\}$' > /dev/null
	if [ $? -eq 0 ]; then
		isNumeric=yes
	fi
			
	if [ $isNumeric = yes ] && [ $1 -gt 0 ] && [ $1 -lt 255 ]; then
		addToLog "calling setup function for valid 3rd octet"
		addTimeToLog
		setupNmNetwork $1
		exit 0
	fi
		

	echo "================================="	>>	$LogFile	2>&1
	echo "                                 "	>>	$LogFile	2>&1
	echo "new seed.sh session starting  ..."	>>	$LogFile	2>&1
	echo "                                 "	>>	$LogFile	2>&1
	date 										>>	$LogFile	2>&1
	echo "                                 "	>>	$LogFile	2>&1
	echo "================================="	>>	$LogFile	2>&1



#	case logic for selection of a given function available
#	======================================================

	while [ true ]

		do

		echo; echo
		echo "Utilities Menu"
		echo "=============="

		PS3="Enter your selection : "
		options=(                   \
		    	"quit"	    	    \
				"draw"		        \
                "cull"	            \
				"seed"		        \
				"JDK"		        \
                "installAptitude"	\
                "addCoreAccounts"   \               
                "supportVirtualBox"	\
                "listPackages"      \
				"miscTests"		    \
				"addTimeToLog"	    \
				"viewLog"		    \
				"clearLog"		    \
			)
	
		select opt in "${options[@]}"
			do
				case "$REPLY" in
	    				$REPLY) "$opt"	2> /tmp/exec.out; break;;
    				esac
			done
			
		sleep 2

		echo; echo

		done

	#while-end


	exit 0

