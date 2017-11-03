#!/bin/bash
#
#	seed.sh
#

	var="$(date +%s)"

    bWeAreDebugging=yes


	LogFile=/var/log/seed.log

	coreAcct=di07zd4

	pkgTransportMethod=filesystem		#	"network" is also supported

	pkgTransportAddress=192.168.1.57

	pkgTransportPath=/media/zcore.d


	# jdk installation definitions
	jdkInstallMethod="net"

	
	
	




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

	if grep -i ubuntu /etc/issue > /dev/null 2>&1; then
		distro=ubuntu
	fi

	if ps -ef | grep -i session | grep -i lubuntu > /dev/null 2>&1; then
		distro=lubuntu
	fi

	if [ -z "$distro" ]; then
		exit 99
	fi

	if echo "$distro" | egrep -i "^mint$|^ubuntu$|^solyd$" > /dev/null 2>&1; then
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
	if [ "$bWeAreDebugging" = yes ]; then
        	turnOnDebugging
	fi
	return
}


turnOnDebugging()
{
    set -x
	#   echo "debugging : now ON"		>>	$LogFile
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


pkgInstalled()
{
	allowForDebugging

    # related cmd saved as reference 	
    # if ! dpkg --get-selections | grep -v deinstall | grep -iE  $pkg

	if [ -z "$1" ]; then
		post "usage : pkgInstalled  pkgName [pkgName arg is required] - exit=9"
		exit 9
	fi

	if ! echo "$extDistro" | grep -i "mubu"; then   # if distro not ubuntu, mint, etc.
		post "INFO : add support for non-ubuntu distros ... exit=9"
        exit 9
	fi

    pkg="$1"

    if ! dpkg -l aptitude 2>&1 | tail -1 | grep "^ii " > /dev/null 2>&1; then      
        if ! apt-get -y install aptitude > /dev/null 2>&1; then
            post "INFO : aptitude install failed, but is required ... exit=9"
            exit 9
        fi
    fi
        
    if ! aptitude show $pkg > /dev/null  2>&1; then
        return 1
    fi

    if aptitude show $pkg 2>&1 | grep "not installed" > /dev/null 2>&1; then
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



seed()
{
	allowForDebugging

	addToLog "setting up new system [$distro] ..."
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


		
	if [ $DE != "none" ]; then
		addToLog "adding $DE to the new system ..."
		addTimeToLog
		$INSTALL	$DE-desktop			>>	$LogFile	2>&1
		status="$?"
		if [ $status -gt 0 ]
			then
			addToLog "$DE add failure [return=$status] ..."
			addTimeToLog
			return 2
		fi
	fi


	if [ $extDistro = "mubu" ]; then
		addToLog "adding misc tools to the new system ..."
		addTimeToLog
		

        for rmvPkg in firefox firefox-locale-en
			do
			addToLog "======================================="
			addToLog "removing $rmvPkg ..."
			addToLog "======================================="				
			
			if ! aptitude -y remove "$rmvPkg" >> $LogFile	2>&1; then
				addToLog "${rmvPkg} : removal failure [exit=$status] ..."
				addTimeToLog
				return 2
			fi
			done
		#for

		# "xfce-notes" pkg may need to be added later

		kernelBuildSet="build-essential linux-headers-`uname -r` dkms"
        toolsSet="ufw gufw geany chromium-browser"

		
		for pkg in $kernelBuildSet  $toolsSet
			do
			addToLog "======================================="
			addToLog "$pkg : adding..."
			addToLog "======================================="			
			
			#$INSTALL "$pkg" >> $LogFile	2>&1
			aptitude -y install "$pkg" >> $LogFile	2>&1			
			status="$?"
			if [ $status -gt 0 ]
				then
				addToLog "$pkg : install failure, [exit=$status]"
				addTimeToLog
				return 2
			fi
			addToLog "$pkg : successful consideration"			
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
			addToLog "tools add failure [exit=$status] ..."
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






nmNetwork()
{
	allowForDebugging

	sessionCore=nmNetwork
	sessionDesc="$sessionCore"

	addToLog "setting up $sessionCore [$sessionDesc] support ..."
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

	addToLog "setting up $sessionCore [$sessionDesc] support ..."
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


addVirtualBox()
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
    post "mount the Guest Additions media now [Menu->Devices->Insert]"
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

    if ! grep -i webupd /etc/apt/sources.list > /dev/null 2>&1; then
        post "the PPA will now install" 
        if ! add-apt-repository ppa:webupd8team/java; then
            return 21
        fi
    fi
        
    post "apt system will now be updated"
    if ! apt-get -y update; then
        post "apt update failed - exit=$?"; read x
        return 213
    fi
               
    post "actual JDK install will now launch"
    if ! apt-get -y install oracle-java8-installer; then
        post "JDK install failed - exit=$?"; read x
        return 213
    fi
        
    post "JDK defaults will now be updated"
    if ! apt-get -y install oracle-java8-set-default; then
        post "JDK env post failed - exit 214"; read x
        return 214
    fi
    
    post "apt system will now be updated, following java defaults setup"
    if ! apt-get -y update; then
        post "apt update failed - exit=$?"; read x
        return 213
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
    allowForDebugging
    
    #   post "calling cull.sh with . ./ syntax"
    
	#. ./cull.sh
    
    bash -x ./cull.sh   -d ./cull-lubuntu.cfg       > /tmp/cull.out 2>&1
    stat=$?
    
    post "cull session completed [exit=$stat] <return>"; read x
       
    return $stat
     
}


showCullLog()
{
    allowForDebugging
    
    if ! cat /tmp/cull.log; then
        post "cat of cull log failed - exit 244"; read x
        return 244
    fi    
    
    post "cull log completed <return>"; read x
    return 0
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

    if ! apt-get -y install aptitude 2>&1; then
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

        post "setting up $sessionCore [$sessionDesc] support ..."
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


sambaStartingPoint()
{
    #   Samba packages
        sambaSet="samba system-config-samba cifs-utils winbind fuse gvfs-backends"
		
    #	ensure that samba starts on boot
		update-rc.d samba defaults 	| tee -a		$LogFile

    #	ensure that samba requests are allow through the firewall
		ufw allow Samba 			| tee -a 		$LogFile
}



#	begin execution here


#	begin execution here
#	====================
#

    distro="lubuntu"
	
	
	echo "$distro" | egrep -i "^mint$|^ubuntu$|^solyd$" > /dev/null 2>&1
	if [ $? -gt 0 ]
	    post "mubu not assigned"
        exit 9
    fi
    
    post "mubu assigned"

    exit 0




	touchLog
	allowForDebugging

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
		

    post "================================="
    post "                                 "
    post "new seed.sh session starting  ..."
    post "                                 "
	date 										>>	$LogFile	2>&1
    post "                                 "
    post "================================="



#	case logic for selection of a given function available
#	======================================================

	while [ true ]

		do

		echo; echo
		echo "Utilities Menu"
		echo "=============="

        # any "whitespace" that occurs, after the backslashes in this list,
        #       is likely to cause blank entries in the menu.

		PS3="Option : "
		options=(                   \
		    	"quit"	    	    \
				"draw"		        \
                "cull"	            \
				"seed"		        \
				"JDK"		        \
                "installAptitude"	\
                "addCoreAccounts"   \
                "addVirtualBox"	    \
                "listPackages"      \
				"miscTests"		    \
				"addTimeToLog"	    \
				"viewLog"		    \
				"showCullLog"	    \
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

