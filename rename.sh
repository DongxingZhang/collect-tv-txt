#!/bin/bash
read -p "old extension:" oldext
read -p "new extension:" newext
dir=$(pwd)
cd $dir
for file in $(ls $dir | grep .$oldext)
do
    name=$(ls $file | cut -d. -f1)
    mv $file ${name}.$newext
    echo "$name.$oldext ====> $name.$newext"
done
echo "all files has been modified."

