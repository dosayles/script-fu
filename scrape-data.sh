#!/bin/bash

#
#
# flatten a data store fetching file types into one dir, build iso file

# call this script with the parent dir name of your archive as an arg...


# FLAGS...set our dir names here...
basedir="/home/doug/cust/"
# list dir to skip (garbage stuff)
options="-iname cookies -o -iname temp* -o -iname documen*"

tgtdir="/tmp/$1/Data/"      # our tmp folder for output and results...
usrdir="Documents and Settings"   #toggle this someday...on vista its now Users instead...detect?
#usrdir="Users"   #toggle this someday...on vista its now Users instead...detect?

srcdir="$basedir$1/$usrdir/"   #toggle this someday
sysdir="$basedir$1/"
logname=$1

set file types to scan for here...kinda messy...
array0=( docs txt rtf pdf )                         # docs
array1=( msdocs doc* xls* ppt* )                         # msdocs
array2=( pics jpg jpeg gif tif* bmp pcx png )   # pics
array3=( music mp3 m4a )                                 # music
array4=( movies mpg wmv avi mov )                     # movies
array5=( weblinks htm* url )                     # movies
#array6=( misc qbk )                                # 

# Create users dirs + sys dir for repositories...
cd "$srcdir"

# Build our directory list...
  dirlist=()                                 # start with empty list
  for f in *; do                             # for each item in...
    if [ -d "$f" ]; then                     # if it's a subdir...
      dirlist=("${dirlist[@]}" "$f")         # add it to the list
    fi
  done

# Create our tmp dirs...
  for dir in "${dirlist[@]}"; do
    mkdir -p $tgtdir"$dir"
  done
  mkdir -p $tgtdir"System"         # this will be our grab bag at end

# Process our files and move them into the tgtdir...
  for dir in "${dirlist[@]}"; do
    echo "Processing files for "$dir"..."
    for (( y=0; y<6; y++ )); do                    #if enabled misc, increase this by one...
      currentdir="$(eval echo \${array$y[0]})"
      mkdir "$tgtdir$dir/$currentdir"
        items="$(eval echo \${#array$y[@]})"
        for (( x=1; x<$items; x++ )); do
          type="*.$(eval echo \${array$y[$x]})"
          cd "$srcdir$dir"
          echo "Processing "$type" files..."
#          TMPNAME=`date +%m%d-%H%M%S`
	  find . -type d \( $options \) -prune -o -iname "$type" -exec cp {} "$tgtdir$dir/$currentdir" \; 
       done
    done
  done

    # Weve done all the users dirs, now lets grab the whole system, sans the user dirs... 
    dir="System"
    echo "Processing files for "$dir"..."
    for (( y=0; y<6; y++ )); do                    #if enabled misc, increase this by one...
      currentdir="$(eval echo \${array$y[0]})"
      mkdir "$tgtdir$dir/$currentdir"
        items="$(eval echo \${#array$y[@]})"
        for (( x=1; x<$items; x++ )); do
          type="*.$(eval echo \${array$y[$x]})"
          cd $sysdir				#at the root...grabbing everything but...
          echo "Processing "$type" files..."
          find . -type d \( $options \) -prune -o -iname "$type" -exec cp {} "$tgtdir$dir/$currentdir" \;
       done
    done

#Cleanup all empty dirs...
cd $tgtdir/..
find . -type d -empty -exec rmdir {} \;  #cleanup empties...
du -h > $logname.txt                  #write some stats...

#mkisofs -r . > /tmp/$logname.iso             #gen our iso image...
