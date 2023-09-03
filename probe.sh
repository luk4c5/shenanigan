#!/bin/bash
cat wildcards |  naabu -exclude-cdn -p 1-65565 -o naabu.txt |  httpx -random-agent -retries 3 -no-color -ldp -o httpx_all.txt 
cat httpx_all.txt  | grep -i '[A-Z]' | cut -d " " -f1 | sort -u > httpx.txt
echo "PROBE FINISHED"
