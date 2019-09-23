#!/bin/bash
for i in $(seq 10 30000);do
	echo -e $(traceroute -f 7 -m 7 -p $i -q 1 -w 3 dofus.com | sed 's/*/#/g' | sed 's/$/\\n/g' | grep -v "traceroute") $i;
done;
