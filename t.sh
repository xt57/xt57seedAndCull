#!/bin/bash
#
#	t.sh
#

    bWeAreDebugging=yes

	LogFile=./t.log	


allowForDebugging()
{
	if [ "$bWeAreDebugging" = yes ]; then
        	turnOnDebugging
	fi
	return 0
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

postToLog()
{
	printf "$1\n"	| tee -a $LogFile
	return 0
}


post()
{
	printf "$1\n"
	postToLog "$1"
	return 0
}


postTime()
{
	varDate="$(date)"
	post "$varDate" 
	return 0
}



usedRootBytes()
{
	allowForDebugging

    kBytes=`df | grep "\/$" | tr -s ' ' | cut -f3 -d' '`    # used root bytes in kbytes
    echo "1024 * $kBytes" | bc
    
	return 0    
}



myMainFun()
{
	allowForDebugging
	
	post "early in myMainFun"
   
    post "free space reported by myMainFun = `usedRootBytes`"

    bash -x ./tFriend.sh   -d ./cull-lubuntu.cfg       2> /tmp/cull.out
    stat=$?

    post "myMainFun is exiting ..."
    
	return 0
}



#	begin execution here
#	====================
#

	allowForDebugging

	postTime

	myMainFun


	exit 0

