#!/bin/bash
#
#	special.sh 
#
#
#   for execution only with ". <name>" syntax within seed.sh
#
#


#   set initial values              =========================================

logFile="/tmp/cull.log"
cullDefFile="./cull-lubuntu.cfg"
cullDefFile="./cull-mint-xfce.cfg"
cullDefFile="./cull-mint-kde.cfg"
cullDefFile="./cull-ubu-kde.cfg"
bWeAreDebugging=yes


#define several utility functions   ============================================

allowForDebugging()
{
	if [ "$bWeAreDebugging" = yes ]; then
        	turnOnDebugging
    else
        turnOffDebugging
	fi
	return
}


turnOnDebugging()
{
    set -x
	#   echo "debugging : now ON"   >>	$logFile
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

postToLogOnly()
{
	printf "$1\n"                   >>	$log	2>&1
	return 0
}


post()
{
	printf "$1\n"
	postToLogOnly "$1"
	return 0
}

verifyLogFile()
{
	touch		$log			    >	/dev/null	2>&1
	chmod 644	$log			    >	/dev/null	2>&1
	file        $log                >   /dev/null   2>&1
	return $?
}



timestampTheLog()
{
	varDate="$(date)"
	post "$varDate"
	return 0
}



# define app-specific functions     =====================================


usage()
{
    echo "Usage: $0 [-d <cullDefPath>] [-l <logPath>]" 1>&2; exit 9;
}


verifyCullDefFile()
{
    (file $cullDefFile > /dev/null 2>&1) || exit 9
    return 0;
}


listInstalledPkgs()
{
	allowForDebugging
	
    dpkg --get-selections| grep -v deinstall | tr '\t' ' ' | tr -s ' ' | cut -f1 -d' '

	return 0
}


pkgIsInstalled()
{
	allowForDebugging

	if [ "$#" -lt 1 ]; then
		post "usage : isPkgInstalled  pkgName (pkgName arg is required) - exit=9"
		exit 9
	fi

    dpkg -l $1 | tail -1 | grep "^ii " > /dev/null 2>&1     # this indicates 'installed'
    stat=$?
    
    if [ "$stat" -eq 0 ]; then
        return 0
    else
        return 1
    fi
}



getRec()
{
	allowForDebugging

    set -x

	if [ "$#" -lt 1 ]; then
		post "usage : getRec  recNum (recNum arg is required) - exit=9"
		exit 9
	fi

    cat $cullDefFile 2> /dev/null | head -$1 | tail -1

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

preOpCleanAndShrink()
{
	allowForDebugging
	
	set -x

    post "preCleanAndShrink() function is active ..."

    post "initial free space = [ `usedRootBytes` ]"

    cleanupAptEnv    
 
    # truncate several log files
    
    find /var/log -size +4k -print | while read path
        do
            truncateThisFile "$path"
        done
    #for

    /usr/sbin/logrotate /etc/logrotate.conf
    
    ls -1 /var/cache | grep -v "^apt$" | while read name
        do
            echo > /dev/null 2>&1
            #   rm -rf /var/cache/$name > /dev/null 2>&1
        done
    #ls-end - end pipe to while
    
    cleanupAptEnv          
     
    post "resulting used space = [ `usedRootBytes` ]"
    
    post "cleanAndShrink() function is exiting ..."
    
	return 0
}

postOpCleanAndShrink()
{
	allowForDebugging
	
	set -x

    post "postCleanAndShrink() function is active ..."

    post "initial free space = [ `usedRootBytes` ]"

    cleanupAptEnv          

    #	aptitude -y update 2>&1 | tee -a $logFile    

    cleanupAptEnv    
 
    # truncate several log files
    
    find /var/log -size +4k -print | while read path
        do
            truncateThisFile "$path"
        done
    #for

    bleachbit --list | grep log | xargs sudo bleachbit --clean
    bleachbit --list | grep apt | xargs sudo bleachbit --clean

    /usr/sbin/logrotate /etc/logrotate.conf
    
    ls -1 /var/cache | grep -v "^apt$" | while read name
        do
            echo > /dev/null 2>&1
            #   rm -rf /var/cache/$name > /dev/null 2>&1
        done
    #ls-end - end pipe to while
    
    rm -rf /usr/lib/firefox     >   /dev/null   2>&1

    cleanupAptEnv          
     
    post "resulting used space = [ `usedRootBytes` ]"
    
    post "cleanAndShrink() function is exiting ..."
    
	return 0
}


printPkgInfoAndReport()
{
	allowForDebugging

    if pkgIsInstalled $pkg > /dev/null 2>&1; then
        echo "\n$pkg is INSTALLED\n\n"   | tee -a $logFile
    else
        echo "\n$pkg is NOT installed\n\n"   | tee -a $logFile
    fi
    
	return 0    
}


installPkgAndReport()
{
	allowForDebugging

	if [ "$#" -lt 1 ]; then
		post "usage : installPkgAndReport  pkgName (pkgName arg is required) - exit=9"
		exit 9
	fi

    if pkgIsInstalled $pkg > /dev/null 2>&1; then
        post "SKIPPING <$pkg> ... already installed"
        return 0
    fi

    if ! apt-get -y install $1 2>&1; then
        post "could not install $1 - quitting"
        return 9
    fi

    return 0
}


removePkgAndReport()
{
	allowForDebugging

    if ! pkgIsInstalled $pkg > /dev/null 2>&1; then
        post "SKIPPING <$pkg> ... not currently installed"
        return 0
    fi

    post "\nCULLing <$pkg>\n\n"
    
    post "logFile = [ $logFile ]"      
        
    options="Aptitude::Delete-Unused=1"
    echo "aa" | aptitude -y -o$options remove $pkg  2>&1 | tee -a $logFile

    #   apt-get -y remove $pkg
        
    if test $? -gt 0; then
        post "\n<$pkg> removal FAILED\n\n"
    else
        post "\n<$pkg> REMOVED\n\n"
    fi   
    
    post "post-removal free space = [ `usedRootBytes` ]"    
    
  	return 0    
}



cleanupAptEnv()
{
    allowForDebugging

    if pkgIsInstalled aptitude > /dev/null 2>&1; then

	# remove all of the orphaned pkgs
    	for x in 1
        	do
        	#   apt-get -y remove $(deborphan)      > /dev/null 2>&1
	
        	options="Aptitude::Delete-Unused=1"
        	echo "aa" | aptitude -y -o$options remove $(deborphan) 2>&1 | tee -a $logFile
            apt-get -y remove --purge $(deborphan)
        	sleep 1
        	done
    	#for-end
    fi

    #   apt-get -y autoremove
    #	apt-get -y remove --purge $(deborphan)

	apt-get -y clean   
	apt-get -y autoclean 
    
	return 0    
}




#   begin    ===========================================


    logFile="/tmp/special.log"

    timeStampTheLog



    allowForDebugging


    post "special session underway ..."
 
    #   preOpCleanAndShrink











	export pkg=radeontool


    post "\used space before xyz removal = [ `usedRootBytes` ]\n"   

    
	allowForDebugging

    if ! pkgIsInstalled $pkg > /dev/null 2>&1; then
        post "SKIPPING <$pkg> ... not currently installed"
        return 0
    fi

    post "\nCULLing <$pkg>\n\n"

    post "logFile = [ $logFile ]"

    options="Aptitude::Delete-Unused=1"
    echo "aa" | aptitude -y -o$options remove $pkg  2>&1 | tee -a $logFile

    #   apt-get -y remove $pkg

    if test $? -gt 0; then
        post "\n<$pkg> removal FAILED\n\n"
    else
        post "\n<$pkg> REMOVED\n\n"
    fi

    post "\used space after xyz removal = [ `usedRootBytes` ]\n"   






    post "\used space before cleanAptEnvl = [ `usedRootBytes` ]\n"   

    cleanupAptEnv          

    post "\used space after cleanAptEnvl = [ `usedRootBytes` ]\n"   







    post "special session completed <return>"; read x
 
    exit 0
