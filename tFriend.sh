#!/bin/bash
#
#	tFriend.sh 
#
#
#   for execution only with ". <name>" syntax within seed.sh
#
#


#   set initial values              =========================================

log="./tFriend.log"
bWeAreDebugging=yes


#define several utility functions   ============================================

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
	#   echo "debugging : now ON"   >>	$logFile
    return 0
}


turnOffDebugging()
{
        set +x
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
    echo "Usage: $0 [-d <defPath>] [-l <logPath>]"; exit 9;
}


myFun1()
{
    allowForDebugging
        
    post "inside tFriends myFun1 function"

    return 0
}


#   main logic                          =========================================

    allowForDebugging

	postTime

    post "tFriend session starting"

	myFun1

    post "tFriend session completed <return>"; read x
 
    exit 0
