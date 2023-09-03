#!/bin/bash
cat wildcards
nuclei -severity info,low,medium,high,critical -no-httpx -l wildcards -o nuc.out
navgix scan -u wildcards | grep -i "vulnerable" | cut -d ":" -f4,5,6 | cut -d " " -f2 | sort | uniq > navgix.txt
