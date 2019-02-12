#!/usr/bin/env bash

set -x
# trap read debug

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

# Source, temp, and target directories
sources="/Users/stingley/Documents/Source/${release}/RPMs/"
uncompressed="/Users/stingley/Documents/Source/${release}/uncompressed/"
target="/Users/stingley/Documents/Source/${release}/jars/"

# Ensure directory structure exists and RPMs are found
if [ ! -d $sources ]; then
    echo "Could not find RPMs directory!"
    exit 11
else
    sudo chown -R stingley $sources
    sudo chmod -R 775 $sources
    cd $sources
    count=$(ls -1 *.rpm 2>/dev/null | wc -l)
    if [[ $count -gt 0 ]]; then
        echo "RPMs appear to exist."
        if [ ! -d $uncompressed ]; then
            mkdir $uncompressed
        fi
        if [ ! -d $target ]; then
            mkdir $target
        fi
        if [ ! -d ${target}java/ ]; then
            mkdir ${target}java/
        fi
        if [ ! -d ${target}c/ ]; then
            mkdir ${target}c/
        fi
        if [ ! -d ${target}js/ ]; then
            mkdir ${target}js/
        fi
        if [ ! -d ${target}perl/ ]; then
            mkdir ${target}perl/
        fi
        if [ ! -d ${target}python/ ]; then
            mkdir ${target}python/
        fi
    else
        echo "Could not find RPMs!"
        exit 12
    fi
fi

# Unpack the RPMs
cd ${sources}
for i in $(ls $sources); do
    tar -xzf $i -C ${uncompressed}
done

echo "RPMs unpacked"

sudo chown -R stingley $uncompressed
sudo chmod -R 775 $uncompressed
cd $uncompressed

# File types supported by Veracode
c=$(find . -type f \( -name "*.a" -o -name "*.c" -o -name "*.h" -o -name "*.cpp" -o -name "*.so" -o -name "*.la" \))
jars=$(find . -type f -name "*.jar")
js=$(find . -type f -name "*.js")
pl=$(find . -type f \( -name "*.pl" -o -name "*.pm" -o -name "*.plx" -o -name "*.pl5" -o -name "*.cgi" \))
pysource=$(find . -type f -name "*.py")
pyall=$(find . -type f \( -name "*.py" -o -name "*.htm" -o -name "*.html" \))

# Gather the source files 
for x in $(ls $jars); do
    cp $x ${target}java/
done
echo "Java code ready"

for x in $c; do
    cp $x ${target}c/
done
cd ${target}c/
tar -czf c.tar.gz ./*
echo "C and C++ code ready"

cd ${uncompressed}
for x in $js; do
    cp $x ${target}js/
done
cd ${target}js/
tar -czf js.tar.gz ./*
echo "Javascript code ready"

cd ${uncompressed}
for x in $pl; do
    cp $x ${target}perl/
done
cd ${target}perl/
tar -czf pl.tar.gz ./*
echo "Perl code ready"

cd ${uncompressed}
for x in $pysource; do
    cp $x ${target}python/
done
cd ${target}python/
tar -czf py.tar.gz ./*
echo "Python code ready"

# Open the target directory and delete the temp directory
cd $target
sudo chown -R stingley $uncompressed
sudo chmod -R 775 $uncompressed
# rm -rf $uncompressed
open .

# We made it!
exit 0
