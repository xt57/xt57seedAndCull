#
#	encode/transcode mov files to .mkv
#

	LogFile=/tmp/encode.log
	completionFile=./sessionCompletion.log

	debugFactor="-vvv"
	stopFactor="--stop-time=10"
	stopFactor=""
	ext=.m4v

	cmd="vlc"

        #   mount -t tmpfs -o size=512m tmpfs /mnt/ramdisk      # exmaple rmadisk creation

boolRamDiskIsPresent()
{
    set -x

    if df -t tmpfs /mnt/ramdisk     > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

encode()
{
    set -x 

    src="$1"

    base=`basename "$src" | cut -f1 -d'.'`
    dst="$base.mkv"

    if boolRamDiskIsPresent; then
        dst="/mnt/ramdisk/$dst"
        rm /mnt/ramdisk/*				>	/dev/null 2>&1
    else
        rm "./$dst"		        		>	/dev/null 2>&1
    fi
    
    transcodeSection="#transcode{vcodec=h264,vb=1024,acodec=mp3,ab=128}"
    stdSection="std{mux=mp4,dst=\"$dst\",access=file}"
	
    $cmd		\
	-I dummy        \
	${debugFactor}	\
	${stopFactor}	\
	"${src}"        \
	--sout "$transcodeSection:$stdSection" \
	vlc://quit					>	/tmp/x.out 2>&1
    #end-block

    stat="$?"; sleep 1

    if boolRamDiskIsPresent; then
        cp -p "$dst" .  #   copy the transcoded file from the ramdisk back to our local dir 
    fi
        
    return $stat
}

#
#	loop throught all of the mpegs and convert them to mkvs
#

    if boolRamDiskIsPresent; then
        printf "ram disk is present\n"
    fi

    ls -1 | grep -v "mkv$" | while read path
	do	

	file "$path" 2> /dev/null | cut -f2 -d: > /tmp/encode.mpeg-stat  2>&1
	if grep -i mpeg /tmp/encode.mpeg-stat > /dev/null 2>&1; then
		printf "\n"					>>	$LogFile
		printf "time            : `date`\n"		>>	$LogFile
		printf "encoding        : $path\n"		>>	$LogFile
		encode "$path"
		printf "    result : $? : $path\n"		>>	$LogFile
		printf "\n"					>>	$LogFile
	fi

	done 
    #whileEnd

    printf "\n"					>>	$CompletionFile
    printf "time            : `date`\n"		>>	$CompletionFile
    printf "encoding completed\n"		>>	$CompletionFile
    printf "\n"					>>	$CompletionFile

    exit 0

