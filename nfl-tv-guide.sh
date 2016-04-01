#!/bin/bash

THEDATE=`date +%Y%m%d`
THEDATE=20081012
cd /tmp
wget http://today.sportingnews.com/sportingnewstoday/$THEDATE/data/snt$THEDATE-dl.pdf
pdftotext snt$THEDATE-dl.pdf
LINE=`grep -n Remote snt$THEDATE-dl.txt | awk -F ":" '{print $1}'`
let "LINE -= 2"
PAGE=`head -n $LINE snt$THEDATE-dl.txt | tail -n 1 | awk -F "\<" '{print $1}'`

pdftops -f $PAGE -l $PAGE -q snt$THEDATE-dl.pdf snt$THEDATE-dl.ps
ps2pdf snt$THEDATE-dl.ps snt$THEDATE.pdf
#lpr -P lp0 -o landscape snt$THEDATE.pdf

#pdftotext snt$THEDATE.pdf
#cat snt$THEDATE.txt | mailx -s "TSN NFL Games..." email.addy@gmail.com

uuencode snt$THEDATE.pdf snt$THEDATE.pdf | mailx -s "TSN NFL Games..." email.addy@gmail.com

rm -rf snt*
