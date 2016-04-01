#!/bin/bash

URL="http://ip.addy.goes.here:82/kffl/statistics.php?Mode=live_scoring&Action=live_scoring_main"
TMPFILE=/tmp/kffl.dump

lynx -dump -nolist $URL > $TMPFILE

START=`grep -n "Week" $TMPFILE | awk -F ":" '{print $1}'`
STOP=`grep -n "Not" $TMPFILE | awk -F ":" '{print $1}'`
let "START -= 1"
LENGTH=$(($STOP - $START))
sed 's/\[arrow_right\.gif\]//g' $TMPFILE > $TMPFILE.2
head -n $STOP $TMPFILE.2 | tail -n $LENGTH | mailx email.addy@gmail.com -s "KFFL Live Scoring..."

rm -rf $TMPFILE*
