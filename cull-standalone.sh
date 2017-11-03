#!/bin/bash
#
#	cull.sh
#

	var="$(date +%s)"


	LogFile=/var/log/cull.log
	dumpLogFile=/var/log/cull-dump.log

    defFile="./cull-lubuntu.cfg"

	if [ $# -lt 9 ]; then
		bDebugging=yes
	fi
	

	# prepare for distro differences
	# ==============================
	distro="null"
	extDistro="null"

#	grep -i mint /etc/issue			>	/dev/null	2>&1
#	if [ $? -eq 0 ]; then
#		distro=lubuntu
#	fi


#	if [ $distro = "" ]; then
#		exit 99
#	fi






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


quit()
{
	echo "exit logic"
	exit 0
}



pkgInstalled()
{
	allowForDebugging

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


cullSession()
{
    allowForDebugging

    cat $defFile | while read defLine
        do
        action=`echo $defLine | cut -f1 -d':'`    
        pkg=`echo $defLine | cut -f2 -d':'`
        
        if [ "$action" = "s" ]; then
            post "\npkg info <$pkg>\n\n"
            aptitude show $pkg
            #   dpkg -l $pkg | grep $pkg
            continue
        fi

        if [ "$action" = "!" ]; then
            :
        else
            continue
        fi

        if ! pkgInstalled; then
            continue
        fi

        post "\nculling <$pkg>\n\n"
        
        echo "aaaa" |   \
            aptitude -y --auto-remove  remove  $pkg >  $dumpLogFile  2>&1

        done
    #end-cat-while

    turnOffDebugging
    
    return 0
}


cull()
{
	allowForDebugging

	addToLog "setting up cull ..."
	addTimeToLog

#	if [ $distro != "mint" ]; then
#		return 39
#	fi

    for pass in 1 2
		do
		    cullSession
		done
    #end-for

	addToLog "$session logic completed ..."
	addTimeToLog

    turnOffDebugging
	return 0
}




#	begin execution here
#	====================
#
	touchLog
	allowForDebugging


	post "================================="
	post
	post "new cull.sh session starting  ..."
	post
	post date
	post
	post "================================="

	post
	post
	post "current distro is $distro"
	post "extended distro is $extDistro"
	post
	post

    cull

	exit 0

