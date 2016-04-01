#!/bin/bash

#
#  ^_^
#
#  Doug's Custom WX script to upload data to Wund...
#
#  Referencing this URL:  http://wiki.wunderground.com/index.php/PWS_-_Upload_Protocol
#
#  For the Lacrosse Tech WS 2813...I run a Windows script to copy the currdat.lst file
#   to my Linux server every five minutes, and this script executes as a cron task
#   parsing the data into a Weather Underground friendly URL for updating...
#
#  !!!THIS SCRIPT REQUIRES LYNX to post the URL to Weather Underground...
#
#  ^_^
#

#
### CHANGE these to reflect your actuals...
#

# Station Information...visit http://www.wunderground.com/wxstation/signup.html to sign up and create account...
wxid=WUND_WS_ID
wxpd=WUND_WS_PASSWD
# Where your data resides...I run a script to create file in every five minutes...
srcFile=/tmp/currdat.lst
#
### END OF CUSTOMIZATION...


# Scrub station ID and password...
wxId="ID="$wxid"&PASSWORD="$wxpd

# Prepping the Date...
#
# NOTE that date is in UTC time, NOT UTC-7 (e.g. local)

#
# DATE FORMATTING NOTES:
#
# Lacrosse Tech WS2813 utilizes its date in NTP format (meaning that second #1 is 1900-01-01)
#  and UNIX Epoch time is used in Linux (meaning that second #1 is 1970-01-01) which ultimately
#  means that there are two different mechanisms to derirve the correct date, based on 32/64bit
#  system...if it appears that your dates are malformed, comment out the 64bit line and
#  uncomment the 32bit code to see if that addresses the issue...

# 32bit doesn't go 1900-01-01 (thats NTP time) ...will only run from 1970-01-01
#  so we need a constant w number seconds from 1900 to 1970
dateCon=2208988800
# LaCrosse Weather Station 2813 sends date in NTP time, or seconds from 1900-01-01
dateNtp=`grep last_actualisation $srcFile | awk -F'"' '{ print $2 }'`
#dateTmp=$(($dateNtp-$dateCon))                                            #32-bit; uncomment to try
#dateUtc=`date -u --date=@"$dateTmp" '+%Y-%m-%d %H:%M:%S'`                 #32-bit; uncomment to try
dateUtc=`date -d '1900-01-01 '$dateNtp' seconds' '+%Y-%m-%d %H:%M:%S'`    #64-bit; enabled by default

# Must encode for URL friendliness... %3A for : and
dateUrl=`echo $dateUtc | sed -e 's/:/\%3A/g'`
dateUrl=`echo $dateUrl | sed -e 's/ /+/g'`
urlDate="&dateutc="$dateUrl

# Wind Direction...
windDir=`grep -A1 wind_direction $srcFile | awk -F'"' '{ print $2 }'`
urlWind="&winddir="`echo $windDir | tr -d ' '`

# Wind Speed...
windSpeed=`grep -A1 wind_speed $srcFile | awk -F'"' '{ print $2 }'`
urlWindSpd="&windspeedmph="`echo $windSpeed | tr -d ' '`

# Temperature...
tempF=`grep -A2 outdoor_temperature $srcFile | grep deg_F | awk -F'"' '{ print $2 }'`
urlTemp="&tempf="$tempF

# Rainfall...
rainIn=`grep -A2 rain_1h $srcFile | grep inch | awk -F'"' '{ print $2 }'`
urlRain="&rainin="$rainIn

# Barometer...
baromIn=`grep -A2 pressure_relative $srcFile | grep inHg | awk -F'"' '{ print $2 }'`
urlBaro="&baromin="$baromIn

# Dew Point...
dewPtF=`grep -A2 dewpoint $srcFile | grep deg_F | awk -F'"' '{ print $2 }'`
urlDew="&dewptf="$dewPtF

# Humidity...
humidity=`grep -A1 outdoor_humidity $srcFile | awk -F'"' '{ print $2 }'`
urlHumidity="&humidity="` echo $humidity | tr -d ' '`

# Software Type
swType=`grep programm_name $srcFile | awk -F'=' '{ print $2 }'`
swType=`echo $swType | sed -e 's/ /_/g' | tr -d ' '`
swVer=`grep programm_version $srcFile | awk -F'=' '{ print $2 }'`
urlSwType="&softwaretype=HeavyWeather_PRO_WS_2800"
urlSwVer="%20version1.00_plus_custom_scripts"

# Miscellaneous...
action="&action=updateraw"

# Logging mechanism...cheesey at best, enable for troubleshooting purposes...
echo -n `date`"; post status: " >> /tmp/wx-update.log

# Assemble URL string...
urlStub=http://weatherstation.wunderground.com/weatherstation/updateweatherstation.php?
urlString=$urlStub$wxId$urlDate$urlWind$urlWindSpd$urlTemp$urlRain$urlBaro$urlDew$urlHumidity$urlSwType$urlSwVer$action

# Post to Weather Underground and log return code...
/usr/bin/lynx -dump $urlString >> /tmp/wx-update.log
