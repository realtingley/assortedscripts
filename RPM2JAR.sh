#!/usr/bin/env bash

function sortcode {
  c=$(find $1 -type f \( -name "*.a" -o -name "*.c" -o -name "*.h" -o -name "*.cpp" -o -name "*.so" -o -name "*.la" \))
  java=$(find $1 -type f -name "*.jar" -o -name "*.war" -o -name "*.ear")
  js=$(find $1 -type f -name "*.js")
  pl=$(find $1 -type f \( -name "*.pl" -o -name "*.pm" -o -name "*.plx" -o -name "*.pl5" -o -name "*.cgi" \))
  pysource=$(find $1 -type f -name "*.py")
  pyall=$(find $1 -type f \( -name "*.py" -o -name "*.htm" -o -name "*.html" \))
  
  for x in $java; do
      cp $x ./java/
  done
  for x in $c; do
      cp $x ./c/
  done
  for x in $js; do
      cp $x ./js/
  done
  for x in $pl; do
      cp $x ./pl/
  done
  for x in $pysource; do
      cp $x ./py/
  done
}

function repackcode {
  langs=( "java" "c" "js" "pl" "py" )
  for y in "${langs[@]}"; do
    if [ -d ./${y} ]; then
      count=$(ls -1 ./${y} 2>/dev/null | wc -l)
      if [[ count -gt 0 ]]; then
        tar -czf ${releasedir}/zipped/${1}-${y}.tar.gz ./${y}/*
      fi
    fi
  done
}

# Make sure this wasn't run as root or with sudo.
if
  [[ $EUID -eq 0 ]]; then
    $echo "Please re-run the script without sudo."
    exit 3
fi

echo "First up: Enter your computer password below:"

# Check for escalation privileges.
checkpriv=$(sudo whoami)

if [ $checkpriv == "root" ]; then
	  echo "Privilege Escalation Allowed"
	else
	  echo "Privilege Escalation Denied, User Cannot Sudo."
	  exit 4
fi

# What release are we scanning?
echo "What release will be scanned?"
read release
user=$(whoami)
# A Note On Directory Structure
# This script assumes a particular directory structure to do its work
# and sort the code correctly for upload.
# By way of example, the following is a valid path example:
# /Users/bob/Documents/Source/Arlington/platform/authentication-38_0_6
# where, parameterized, the code sees it as:
# /Users/$(whoami)/Documents/Source/${release}/${component}/${service}
# and each service directory contains the RPMs that are part of that release
releasedir="/Users/${user}/Documents/Source/${release}"

# Ensure directory structure exists and RPMs are found
if [ ! -d $releasedir ]; then
    echo "Could not find RPMs directory!"
    exit 11
fi

sudo chown -R ${user} $releasedir
sudo chmod -R 775 $releasedir

cd $releasedir
if [ ! -d ${releasedir}/zipped ]; then
  mkdir zipped
else
  rm -rf ${releasedir}/zipped/*
fi
for component in $(ls -d *); do
  cd ${releasedir}/${component}
  for service in $(ls -d *); do
    cd ${releasedir}/${component}/${service}
    subdirs=( "${service}-bin" "java" "c" "js" "pl" "py" )
    for i in "${subdirs[@]}"; do
      if [ ! -d ${releasedir}/${component}/${service}/${i} ]; then
        mkdir ${releasedir}/${component}/${service}/${i}
      else
        rm -rf ${releasedir}/${component}/${service}/${i}/*
      fi
    done
    for package in $(find . -type f -name "*.rpm"); do
# If we wind up needing to go one more level of granularity, this is the code
# to do it with.
#        name=$(echo $package | sed -e s/\.el6.x86_64.rpm//g -e s/\.x86_64.rpm//g -e s/\.noarch.rpm//g -e s/\-centos7.rpm//g -e s/\.rpm//g)
#        mkdir ./${serivice}-${name}-bin
      tar -xzf $package -C ./${service}-bin/
    done
    sudo chown -R $user ./${service}-bin && sudo chmod -R 775 ./${service}-bin
    sortcode ${service}-bin
#    repackcode ${service}
  done
done

# We made it!
exit 0
