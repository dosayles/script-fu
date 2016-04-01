#!/bin/bash

team=mil
teamid=8
#team=ari
#teamid=29



file=/tmp/msg.tmp
dump=/tmp/dump.tmp
stand=/tmp/stand.tmp

mainurl="http://m.espn.go.com/mlb/clubhouse?teamId="$teamid
baseurl=http://assets.espn.go.com/media/apphoto/
srcurl="http://sports.espn.go.com/mlb/teams/photo?team="$team

#s=" | "
espn="<a href=http://sports.espn.go.com/mlb/clubhouse?team="$team"><img src=http://logos.espn.com/favicon.ico></a>"
yahoo="<a href=http://sports.yahoo.com/mlb/teams/"$team"><img src=http://www.yahoo.com/favicon.ico></a>"
mlb="<a href=http://mlb.com/index.jsp?c_id="$team"><img src=http://mlb.com/favicon.ico></a>"
mespn="<a href=http://m.espn.go.com/mlb/clubhouse?teamId="$teamid"><img src=http://logos.espn.com/favicon.ico border=0></a>"
myahoo=""
mmlb="<a href=http://wap.mlb.com/index.jsp?c_id="$team"><img src=http://mlb.com/favicon.ico></a>"

photo=`lynx -dump $srcurl | grep -m 1 thumbnail |  awk -F "\]" '{print $2}' | sed -e 's/\[//g' | sed -e 's/_thumbnail//g'`

header="<img src=$baseurl$photo border=0><br>"
footer="</tt><hr>Links: "$espn$yahoo$mlb"<br>Mobile: "$mespn$mmlb

lynx -dump -nolist $mainurl > $dump
echo $header > $file
echo `grep LAST $dump`"<br>" >> $file 
echo `grep NEXT $dump`"<br><br><tt>" >> $file 

start=`grep -n GB $dump | awk -F ":" '{print $1}'`
let "start += 6"
head -n $start $dump | tail -n 6 > $stand

while read line
do
  if `echo ${line} | grep -i $team 1>/dev/null 2>&1`; then
    echo "<b>"$line"</b><br>" >> $file
  else
    echo $line"<br>" >> $file
  fi
done < $stand


echo $footer >> $file

subject="Daily Crew Update..."
./email-to-blogger.pl $file $subject
