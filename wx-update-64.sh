#!/bin/bash

#
#  ^_^
#
#  Doug's Custom WX script to upload data to Wund...
#
#  Referencing this URL:  http://wiki.wunderground.com/index.php/PWS_-_Upload_Protocol
#
#
#
#
#  ^_^
#

#end result string must look like this:
#http://weatherstation.wunderground.com/weatherstation/updateweatherstation.php?ID=KCASANFR5&PASSWORD=XXXXXX&dateutc=2000-01-01+10%3A32%3A35&winddir=230&windspeedmph=12&windgustmph=12&tempf=70&rainin=0&baromin=29.1&dewptf=68.2&humidity=90&weather=&clouds=&softwaretype=vws%20versionxx&action=updateraw
wxid=KAZGOODY14
wxpd=PASSWD

srcFile=/tmp/currdat.lst
logFile=/tmp/wx-update.log
echo -n `date`"|vars_set" >> $logFile

# Prep for station ID and password...
#
#
wxId="ID=KAZGOODY14&PASSWORD=r3dWUND"
#echo $wxId

# Prepping the Date...
#
#
# NOTE that date is in UTC time, NOT UTC-7 (e.g. local)
#date -d '1900-01-01 3527505193 seconds' '+%Y-%m-%d %H:%M:%S'

# HUGE PROB: 32bit doesn't go 1900-01-01 (thats NTP time)
#            will only run from 1970-01-01
# Need a constant w number seconds from 1900 to 1970
dateCon=2208988800
# LaCrosse Weather Station 2813 sends date in NTP time, or seconds from 1900-01-01
dateNtp=`grep last_actualisation $srcFile | awk -F'"' '{ print $2 }'`
/bin/cp $srcFile $srcFile.$dateNtp
echo -n "|copy_complete" >> $logFile
dateTmp=$dateNtp                                        # 32bit
#dateTmp=$(($dateNtp+17))                                        # 32bit
#dateUtc=`date -u --date=@"$dateTmp" '+%Y-%m-%d %H:%M:%S'`             # 32bit
dateUtc=`date -u -d '1900-01-01 '$dateTmp' seconds' '+%Y-%m-%d %H:%M:%S'` # 64bit
#echo "Tshooting: "$dateNtp" xfers into "$dateUtc
# Must encode for URL friendliness... %3A for : and
dateUrl=`echo $dateUtc | sed -e 's/:/\%3A/g'`
dateUrl=`echo $dateUrl | sed -e 's/ /+/g'`
urlDate="&dateutc="$dateUrl
#echo $urlDate
echo -n "|"$urlDate >> $logFile

# Prep for winddir
#
#
windDir=`grep -A1 wind_direction $srcFile | awk -F'"' '{ print $2 }'`
urlWind="&winddir="`echo $windDir | tr -d ' '`
#$windDir=`echo $windDir | sed -e 's/ //'`
#urlWind="&winddir="$windDir
#echo $urlWind


# Prep for windspeed
#
#
windSpeed=`grep -A1 wind_speed $srcFile | awk -F'"' '{ print $2 }'`
urlWindSpd="&windspeedmph="`echo $windSpeed | tr -d ' '`
#urlWindSpd="&windspeedmph="` echo ${windSpeed/ /}`

# Prep for temp
#
#
tempF=`grep -A2 outdoor_temperature $srcFile | grep deg_F | awk -F'"' '{ print $2 }'`
urlTemp="&tempf="$tempF

# Prep for rainfall
#
#
rainIn=`grep -A2 rain_1h $srcFile | grep inch | awk -F'"' '{ print $2 }'`
urlRain="&rainin="$rainIn


# Prep for barometer
#
#
baromIn=`grep -A2 pressure_relative $srcFile | grep inHg | awk -F'"' '{ print $2 }'`
urlBaro="&baromin="$baromIn

# Prep for dewpoint
#
#
dewPtF=`grep -A2 dewpoint $srcFile | grep deg_F | awk -F'"' '{ print $2 }'`
urlDew="&dewptf="$dewPtF

# Prep for humidity
#
#
humidity=`grep -A1 outdoor_humidity $srcFile | awk -F'"' '{ print $2 }'`
urlHumidity="&humidity="` echo $humidity | tr -d ' '`
#urlHumidity="&humidity="`echo ${humidity/ /}`

# Prep for software type
#
#
swType=`grep programm_name $srcFile | awk -F'=' '{ print $2 }'`
swType=`echo $swType | sed -e 's/ /_/g' | tr -d ' '`
swVer=`grep programm_version $srcFile | awk -F'=' '{ print $2 }'`
urlSwType="&softwaretype=HeavyWeather_PRO_WS_2800"
urlSwVer="%20version1.00_plus_customized_scripts"

# Miscellaneous...
action="&action=updateraw"

# Assemble URL string...
urlStub=http://weatherstation.wunderground.com/weatherstation/updateweatherstation.php?
urlString=$urlStub$wxId$urlDate$urlWind$urlWindSpd$urlTemp$urlRain$urlBaro$urlDew$urlHumidity$urlSwType$urlSwVer$action
#urlString=$urlStub$wxId$urlWind$urlWindSpd$urlTemp$urlRain$urlBaro$urlDew$urlHumidity$urlSwType$urlSwVer$action
echo -n "|URL_to_post:"$urlString >> $logFile
echo -n "|post_status:" >> $logFile
/usr/bin/lynx -dump $urlString >> $logFile
#echo $urlString
