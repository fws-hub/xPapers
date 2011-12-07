#!/bin/sh
filename=$1
id=0

echo "cleaning bibtex"

tmp=$filename.tmp
rm $tmp

#how many lines are in the file?
lines=`wc -l $filename | awk '{print $1}'`

#loop through every line
for i in `seq 1 $lines` ; do
    line=`head -$i $filename | tail -1`
    
    #test if the line is of the format @sometext{ it should be @sometext{key,
    echo $line | grep "^\@[A-z]*{$" > /dev/null
    if [ "$?" = "0" ] ; then
    
	#add the key if the key is missing
	echo $line | sed "s/{/{$id,/" >> $tmp
	id=`expr $id + 1`
    else
	#if not just print the line
	echo $line >> $tmp
    fi

done



#look for types that xpapers can't handle
for type in misc inproceedings techreport unpublished manual conference ; do
    lines_to_remove=$lines_to_remove" "`grep -n  "^\@$type{[[:alnum:]+_-]*,$" $tmp | awk -F: '{print $1}'`
done
#echo delete $lines_to_remove
stop_printing=0

rm $filename.out

for i in `seq 1 $lines` ; do
    dont_print=0

    line=`head -$i $tmp | tail -1`

    for j in $lines_to_remove ; do
	#look for lines to remove
	if [ "$j" = "$i" ] ; then
	    dont_print=1 # stop this line printing
	    stop_printing=1 #supress further printing
	fi
    done
    
    #print lines unless we have don't print or stop_printing set
    if [ "$dont_print" = "0" -a "$stop_printing" = "0" ] ; then
	echo $line >> $filename.out
    fi
    
    #start printing again when we hit a line with a lone }
    if [ "$stop_printing" = "1" ] ; then
	echo $line | grep "^}$" > /dev/null
	if [ "$?" = "0" ] ; then
	    stop_printing=0
	fi
    fi
    
done

rm $filename
mv $filename.out $filename

