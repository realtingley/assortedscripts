#!/bin/bash

sources=/Users/stingley/Documents/JARs/$RELEASE/RPMs/
uncompressed=/Users/stingley/Documents/JARs/$RELEASE/uncompressed/
target=/Users/stingley/Documents/JARs/$RELEASE/jars/

if [ ! -d $sources ]; then
    echo "Couldn't find source directory"
    exit 11
else
    cd $sources
    count=$(ls -1 *.jar 2>/dev/null | wc -l)
    if [ $count > 0 ]; then
        echo "Source files appear to exist."
        if [ ! -d $uncompressed ]; then
            mkdir $uncompressed
        fi
        if [ ! -d $target ]; then
            mkdir $target
        fi
    fi
fi

for i in $(ls $sources):
do
    tar -xzf $i -C $uncompressed
done

echo "RPMs unpacked!"

cd $uncompressed
jars=$(find . -type f -name "*.jar")
for x in $jars:
do
    cp $x $target
done

echo "JARs gathered"

cd $target
#rm -rf $uncompressed
open .

exit 0
