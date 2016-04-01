#!/bin/bash

THEDATE=`date +%A", "%b" "%d", "%Y`
CHANNELURL="http://www.digitalcaffeine.com/directv/hd/index.php"
DTVLIST="/tmp/directv-channel.list"
P1URL="http://www.hdsportsguide.com/14days/"
P1TMP="/tmp/pass1.tmp"
MASTER="/tmp/master.msg"
SPORTS="NFL\|MLB\|NHL"	#Later, test & add GOLF AUTO
CHANNELHELP="2\|U\|PLUS"



cd /tmp
echo > $MASTER; echo >> $MASTER

get_channel_numb ()
{ if [ ! -e "$DTVLIST" ]; then
    echo "5" > $DTVLIST; echo "CBS" >> $DTVLIST
    echo "10" >> $DTVLIST; echo "Fox" >> $DTVLIST
    echo "12" >> $DTVLIST; echo "NBC" >> $DTVLIST
    echo "15" >> $DTVLIST; echo "ABC" >> $DTVLIST
    lynx -dump -nolist -width=200 $CHANNELURL >> $DTVLIST
  fi
  
  # Fetch the CHANNEL from the DTVLIST...
  LINENUMB=`grep -n -w $CHANNEL $DTVLIST | awk -F ":" '{print $1}' | head -n 1`
  let "LINENUMB -= 1"
  CHANNELNO=`head -n $LINENUMB $DTVLIST | tail -n 1 | awk -F " " '{print $1}'`
  if [ -z "$CHANNELNO" ]; then
    CHANNELNO="Unk*"
  fi
}

  lynx -dump -nolist -width=200 $P1URL > $P1TMP
  P1START=`grep -n -o SPORT -m 1 $P1TMP | awk -F ":" '{print $1}'`
  P1STOP=`grep -n -o SPORT -m 2 $P1TMP | awk -F ":" '{print $1}'| tail -n 1`
  let "P1STOP -= 2"; P1LENGTH=$(($P1STOP - $P1START))
  head -n $P1STOP $P1TMP | tail -n $P1LENGTH > $P1TMP.3

  #   When a game wraps to a second line...ala, the World Series, which isn't just a regular season
  # game, they have to announce it's game 1 blah blah blah...what a serious PITA...
  NEED=0
  while read LINE
  do
    TEST=`echo $LINE | grep $SPORTS`
  if [ $NEED -eq 0 ]; then
    if [ -n "$TEST" ]; then
      TEST2=`echo $LINE | grep ")"`
      if [ -n "$TEST2" ]; then
        echo $LINE >> $P1TMP.2
      else
        echo -n $LINE"--" >> $P1TMP.2
        NEED=1
      fi
    fi
  else
    echo $LINE >> $P1TMP.2
    NEED=0
  fi
  done < $P1TMP.3

# this next part is for reformatting the output in a way which we wanna present the data in its final
# result...mostly its just rearranging fields around...
  while read LINE
  do
    FIELDS=`echo $LINE | awk '{print NF}'`  #this counts the number of fields for the line


    # we need to check if its a two-name channel or not, we'll check the second name...e.g.
    # MSG PLUS, well check for "PLUS"...if found, we'll assume grab previous field and join
    # to form a new channel MSG-PLUS...i hope...


    CHANNEL=`echo $LINE | awk -F " " '{print $(NF-1)}'`
    CHANNELTEST=`echo $CHANNEL | grep $CHANNELHELP`
    if [ -n "$CHANNELTEST" ]; then
      CHANNEL=`echo $LINE | awk -F " " '{print $(NF-2)"-"$(NF-1)}'`
    fi

    get_channel_numb
    GAMETIME=`echo $LINE | awk -F " " '{print $2$3"\t"$1"-"}'`
    CHANNELINFO=" > "$CHANNEL`echo $LINE | awk -F " " '{print $NF"/DirecTV 000"}' | sed -e "s/000/$CHANNELNO/g"`
    MATCHUP=`echo $LINE | awk -F "M " '{print $2}' | awk -F " \(" '{print $1}'`
    CUTOFF=`echo $MATCHUP | awk -F " " '{print $NF}'`
    MATCHUP=`echo $MATCHUP | sed "s/ $CUTOFF//g"`

#    exceptions    ### MAYBE use exceptions for channels?  e.g. FSN A -> FSN-A???

echo $GAMETIME$MATCHUP$CHANNELINFO >> $MASTER

#    echo $LINE | awk -F " " '{print $2$3"\t"$1"-"$5"\n > "$9$10"/DirecTV 000"}' | sed -e "s/000/$CHANNELNO/g" >> $MASTER
#    fi
  done < $P1TMP.2

mv $MASTER $MASTER.tmp
sed -e 's|> |\n > |g' $MASTER.tmp > $MASTER
SPORTS=`echo $SPORTS | sed -e 's/\\\|/ /g'`
REFURL=`echo $P1URL | awk -F "14days" '{print $1}'`
echo "____" >> $MASTER;echo "All times Eastern" >> $MASTER; echo "*Unk:  Unavailable as a DirecTV-HD service" >> $MASTER
echo "The only sports listed are: "$SPORTS >> $MASTER
echo >> $MASTER; echo "References:" >> $MASTER
#echo "http://thesportingnews.com" >> $MASTER
echo "http://hdsportsguide.com" >> $MASTER
echo "http://directv.com" >> $MASTER
#echo "http://espn.com" >> $MASTER
echo "" >> $MASTER
echo "Known issues:" >> $MASTER
echo "__Only grabbing the first of multiple channels listed" >> $MASTER
echo "__NFL channels are not being resolved" >> $MASTER
echo "__Enhancement:  Game summaries..." >> $MASTER

cat $MASTER | mailx email.addy@gmail.com -s "$THEDATE"" Sports Broadcast in HD"
rm -rf $P1TMP* $MASTER*




##
# Whoa...whole new theory of ops here...
#lynx -dump -nolist "http://sports.directv.com/local_schedule.htm?sport=4&zip=85338&Submit=View+Schedule" > dtv-unk
#
