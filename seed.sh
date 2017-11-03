#!/bin/bash
#
#	seed.sh
#

# tell


	var="$(date +%s)"

    bWeAreDebugging=no


	LogFile=/var/log/seed.log
	LogFile=/tmp/seed.log	

	coreAcct=di07zd4

	pkgTransportMethod=filesystem		#	"network" is also supported

	pkgTransportAddress=192.168.1.57

	pkgTransportPath=/media/zcore.d

		
	wallpaperMode=tile
	wallpaperImage="$HOME/weave.jpg"

    invokingUserName=`echo $HOME | cut -f3 -d'/'`



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

	if grep -i lmde /etc/issue > /dev/null	2>&1; then
		distro=lmde
		extDistro=debian
	fi


	if [ -z "$distro" ]; then
		exit 99
	fi


	echo "$distro" | egrep -i "mint|ubuntu|solyd" > /dev/null 2>&1
	if [ $? -eq 0 ]; then
	    extDistro=mubu
	fi

		    
	if [ "$extDistro" = mubu ] || [ "$extDistro" = debian ]; then
		UPDATE="            apt-get -yuq update"
		DISTUPDATE="        apt-get -yuq upgrade"
		UPGRADE="echo I\n | apt-get -yuq upgrade"
		INSTALL="           apt-get -yuq install"
		REMOVE="            apt-get -yuq remove"
		DE=none
	fi

	if [ $distro = mint ]; then
		DISTUPDATE="        apt-get -yuq install   mintupdate"
	fi

	if [ "$distro" = centos ] || [ "$distro" = fedora ]; then
		DISTUPDATE="        yum -y update"
		UPDATE="            yum -y update"
		UPGRADE="           yum -y update"
		INSTALL="           yum -y install"
		REMOVE="            yum -y remove"
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

	return 0
}



logDistroInfo()
{
	allowForDebugging

	addToLog "distro = [ ${distro} ]"

	return 0
}



updateTheSystem()
{
	allowForDebugging

    set -x

	$UPDATE 2>&1 | tee -a					$LogFile

	return 0
}


usedRootBytes()
{
	allowForDebugging

    kBytes=`df | grep "\/$" | tr -s ' ' | cut -f3 -d' '`    # used root bytes in kbytes
    echo "1024 * $kBytes" | bc
        
	return 0    
}





truncateThisFile()
{
	allowForDebugging

    post "initial $1 = `ls -lt $1`"
    rm -f >     $1      2>&1    | tee -a    $LogFile
    touch       $1      2>&1    | tee -a    $LogFile
    chmod g+rw  $1      2>&1    | tee -a    $LogFile
    post "resulting $1 = `ls -lt $1`"
    
	return 0    
}



truncateCertainMubuFiles()
{
	allowForDebugging
	
	set -x

    post "truncateCertainMubuFiles() function is active ..."

    if [ $extDistro != "mubu" ]; then
        return 0
    fi

    post "initial free space = `usedRootBytes`"

    # truncate several files before we begin
    
    find /var/log -size +4k -print | while read path
        do
            truncateThisFile "$path"
        done
    #for

    apt-get -y clean

    post "resulting used space = `usedRootBytes`"
    
    post "truncateCertainMubuFiles() function is exiting ..."
    
	return 0
}





seed()
{
	allowForDebugging

    set -x

	post "setting up new system [$distro] ..."
	post "extended distro title [$extDistro] ..."
		
	addTimeToLog

	reviewForSpecificHardware

	post "we may need to add debconf-utils to a new mint system, skipping ..."


	if [ $extDistro = "mubu" ]; then
	    :
        #   gsettings set org.gnome.desktop.session idle-delay 0	

        #   kernelBuildSet="build-essential linux-headers-`uname -r` dkms"
	fi

	if [ $distro = "lubuntu" ]; then
		addTimeToLog	
		post "considering wallpaper config"
		
		cmd=""
		if test -z "$wallpaperMode";then
            cmd="pcmanfm --wallpaper-mode=center"
        else
            cmd="pcmanfm --wallpaper-mode=$wallpaperMode"
        fi
        
        if file "$wallpaperImage" > /dev/null 2>&1; then
            cmd="$cmd -w $wallpaperImage"
        else
            cmd=""
        fi
    
        if ! test -z "$cmd"; then
            echo "$cmd"             >   $HOME/Desktop/wallpaper.txt 2> /dev/null
            chmod 644                   $HOME/Desktop/wallpaper.txt 2> /dev/null
            chown $invokingUserName     $HOME/Desktop/wallpaper.txt 2> /dev/null
        fi
    
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



	if [ $distro = "suse" ]; then
		addToLog "adding basic tools to the new mint system ..."
		for Pkg in gcc make kernel-default-devel
			do
			$INSTALL $Pkg	2>&1 | tee -a		$LogFile
			done
		#for
	fi


	echo "rebooting new system ..."	2>&1 | tee -a		$LogFile
	date 							2>&1 | tee -a		$LogFile
	#	reboot

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

	return 0
}


cleanAndShrink()
{
	allowForDebugging
	
	set -x

    post "CleanAndShrink() function is active ..."

    #   post "initial free space = [ `usedRootBytes` ]"

    # remove all of the orphaned pkgs
    for x in 1 2 3 4 5 6 7
        do
        #   apt-get -y remove $(deborphan)      > /dev/null 2>&1
        
        options="Aptitude::Delete-Unused=1"
        echo "aa" | aptitude -y -o$options remove $(deborphan) 2>&1 | tee -a $logFile       
                
        sleep 1
        done
    #for-end


    aptitude -y update 2>&1 | tee -a $logFile    


    bleachbit --list | grep log | xargs sudo bleachbit --clean
    bleachbit --list | grep apt | xargs sudo bleachbit --clean

    /usr/sbin/logrotate /etc/logrotate.conf
    
    rm -rf /usr/lib/firefox     >   /dev/null   2>&1

    #   post "resulting used space = [ `usedRootBytes` ]"
    
    post "cleanAndShrink() function is exiting ..."
    
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
    
    post "copying Guest Additions installation script to /tmp"  
    
    cp -p $gaDir/*.run  /tmp    2>&1 | tee -a LogFile
    
    post "now executing Guest Additions installation <please wait>"  
    
    echo y | bash $gaDir/*.run  2>&1 | tee -a $LogFile
    

	post "updating vbox group memberships ..."
	groupadd vboxusers	        2>&1 | tee -a $LogFile	
	groupadd vboxsf		        2>&1 | tee -a $LogFile	

	addCoreAccounts
	for acct in xt57 di07zd4 iansblues kim
		do
        usermod -a -G vboxusers $acct	2>&1	| tee -a	$LogFile
        usermod -a -G vboxsf    $acct	2>&1	| tee -a	$LogFile
        post "<$acct> now a member of virtualbox groups"		
	done
	    
    msg="VirtualBox now fully supported, if no errors were reported <return>"
    post "$msg"; read x
    
    return 0
}


JDK7()
{
    allowForDebugging

    sessionCore=JDK

    Post "setting up $sessionCore support ..."
    addTimeToLog
        
    targetVersion="1.7."


    apt-get purge openjdk-\*    > /dev/null 2>&1    # purge openjdks


    javac -version 2>&1 | grep '1\.7\.' /dev/null 2>&1
    if [ $? -eq 0 ]; then
        post "JDK $targetVersion already installed - exit 245"
        javac -version   2>&1   | tee -a $LogFile
        read x
        return 245
    fi

    javac -version 2>&1 | grep -i openjdk /dev/null 2>&1
    if [ $? -eq 0 ]; then
        post "openjdk is still installed - we require oracles java - exit 249"
        javac -version   2>&1   | tee -a $LogFile
        read x
        return 245
    fi

    if [ $extDistro != "mubu" ]; then
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
    if ! apt-get -y install oracle-java7-installer; then
        post "JDK install failed - exit=$?"; read x
        return 213
    fi
 
        post "JDK defaults will now be updated"
    if ! apt-get -y install oracle-java7-set-default; then
        post "JDK 7 defaults processing failed - exit 214"; read x
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


    #  this following code needs to become more effective and portable

    apt-get -y remove openjdk-7-jre:amd64               > /dev/null 2>&1
    apt-get -y remove openjdk-7-jre-headless:amd64      > /dev/null 2>&1

    # remove all of the orphaned pkgs
    for x in 1 2 3
        do
        #   apt-get -y remove $(deborphan)      > /dev/null 2>&1
        
        options="Aptitude::Delete-Unused=1"
        echo "aa" | aptitude -y -o$options remove $(deborphan) 2>&1 | tee -a $logFile       
                
        sleep 1
        done
    #for-end

    bleachbit --list | grep log | xargs sudo bleachbit --clean
    bleachbit --list | grep apt | xargs sudo bleachbit --clean

    return 0
}



JDK8()
{

    allowForDebugging

    sessionCore=JDK

    Post "setting up $sessionCore support ..."
    addTimeToLog
        
    targetVersion="1.8."


    apt-get purge openjdk-\*    > /dev/null 2>&1    # purge openjdks


    javac -version 2>&1 | grep '1\.8\.' /dev/null 2>&1
    if [ $? -eq 0 ]; then
        post "JDK $targetVersion already installed - exit 245"
        javac -version   2>&1   | tee -a $LogFile
        read x
        return 245
    fi

    javac -version 2>&1 | grep -i openjdk /dev/null 2>&1
    if [ $? -eq 0 ]; then
        post "openjdk is still installed - we require oracles java - exit 249"
        javac -version   2>&1   | tee -a $LogFile
        read x
        return 245
    fi

    if [ $extDistro != "mubu" ]; then
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
        post "JDK 8 defaults processing failed - exit 214"; read x
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


    #  this following code needs to become more effective and portable

    apt-get -y remove openjdk-8-jre:amd64               > /dev/null 2>&1
    apt-get -y remove openjdk-8-jre-headless:amd64      > /dev/null 2>&1

    # remove all of the orphaned pkgs
    for x in 1 2 3
        do
        #   apt-get -y remove $(deborphan)      > /dev/null 2>&1
        
        options="Aptitude::Delete-Unused=1"
        echo "aa" | aptitude -y -o$options remove $(deborphan) 2>&1 | tee -a $logFile       
                
        sleep 1
        done
    #for-end

    bleachbit --list | grep log | xargs sudo bleachbit --clean
    bleachbit --list | grep apt | xargs sudo bleachbit --clean

    return 0




















    #   the following code can be removed, once we are comfortable with the code above


    exit 9

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

    if [ $extDistro != "mubu" ]; then
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
int-xfce


cull()
{
    allowForDebugging

    truncateCertainMubuFiles
		
    #   post "calling cull.sh with . ./ syntax"
    
	#. ./cull.sh
    
    # bash -x ./cull.sh   -d ./cull-lubuntu.cfg       2> /tmp/cull.out
    bash ./cull.sh   -d ./cull-mint-xfce.cfg
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
	                cull-mint-xfce.cfg    \
	                weave.jpg
	    do
        rm ./$name                  >   /dev/null   2>&1
        rm ./$name.1                >   /dev/null   2>&1     	
        rm ./$name.2                >   /dev/null   2>&1
        rm ./$name.3                >   /dev/null   2>&1

	    wget    xt57.net/$name
	    
	    post "new $name file has checksum of : `sum ./$name | cut -f1 -d' '`"
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

	for acct in xt57 di07zd4 iansblues kim
		do
		if id $acct > /dev/null 2>&1; then
			continue
		else
			adduser $acct	2>&1		| tee -a	$LogFile
			post "<$acct> adduser status = $?"
		fi
	done
	
    post "processing completed <return>"; read x
    postTime

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

	touchLog
	allowForDebugging

	post "invoking user name    : $invokingUserName"
	post "current distro        : $distro"
	post "extended distro       : $extDistro"
	post

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
	date 			| tee -a                    $LogFile
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


        #   truncateCertainMubuFiles

		PS3="Option : "
		options=(                   \
		    	"quit"	    	    \
				"draw"		        \
                "cull"	            \
				"seed"		        \
				"JDK7"		        \
				"JDK8"		        \
                "installAptitude"	\
                "addCoreAccounts"   \
                "addVirtualBox"	    \
                "cleanAndShrink"    \
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
                        $REPLY)     \
                                "$opt"	2> /tmp/exec.out;
                                break;;
    				esac
            done
			
		sleep 2

		echo; echo

		done

	#while-end


	exit 0

