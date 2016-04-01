#!/bin/bash

#dummy script to capture bssid + channel of command line essid...

bssid="nothing"
channel="none"

#iwlist eth1 scan > dump.txt

#first, we need to find the line number of the paragraph we want...
ctr=0
while read line
do
	if [[ "$line" =~ "$1" ]]; then
		starta=$(( $ctr - 1 ))
		startc=$(( $ctr + 3 ))
	fi
	let "ctr++"
done < dump.txt
echo $start

#second, now we fetch the raw line data we need...
ctr=0
while read line
do
	if [ "$ctr" == "$starta" ]; then
		bssid=`echo $line | awk -F ": " '{print $2}'`
	elif [ "$ctr" == "$startc" ]; then
		channel=`echo $line | awk -F ":" '{print $2}'`
	fi
	let "ctr++"
done < dump.txt


echo "For ESSID "$1", the bssid is "$bssid" and the channel is "$channel"..."
