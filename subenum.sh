#!/bin/bash
cat wildcards | subfinder -silent -all -o sf_output.txt 2>/dev/null >/dev/null
cat wildcards | assetfinder --subs-only >> af_output.txt
cat wildcards | timeout 1200 gauplus -subs -t 5 -random-agent -o gauplus_all.txt;cat gauplus_all.txt | unfurl -u domains | anew gauplus.txt
cat wildcards | timeout 1200 waybackurls >> xsxs.txt;cat xsxs.txt| unfurl -u domains | anew wayback_output.txt
for i in $(cat wildcards);do findomain -t $i -u fd_output_`echo $i | cut -d "." -f1`.txt;done
for i in $(cat wildcards);do /opt/crt.sh $i >> crt.txt;done
for i in $(cat wildcards);do timeout 600 amass enum -passive -d $i -o `echo $i | cut -d "." -f1`.amass.txt;done 
#curl https://raw.githubusercontent.com/proabiral/Fresh-Resolvers/master/resolvers.txt -o /opt/resolvers.txt;for i in $(cat wildcards);do timeout 1500 puredns bruteforce /opt/assetnote.txt $i -r /opt/resolvers.txt  -w `echo $i | cut -d "." -f1`.txt;done
cat * | unfurl domains | grep -i "$(cat wildcards| sed -z 's/\n/\\|/g;s/,$/\n/' | sed 's/\(.*\)\\|/\1/')" | sort -u > subs
rm wayback_output.txt gauplus_all.txt 
gotator -sub subs -perm /opt/permutations_list.txt -depth 1 -numbers 10 -mindup -adv -md >> permuts.txt
cat permuts.txt | timeout 1500 dnsx -silent -o permutations.txt
cat permutations.txt subs | grep -i "$(cat wildcards| sed -z 's/\n/\\|/g;s/,$/\n/' | sed 's/\(.*\)\\|/\1/')" | sort -u > subs2;mv subs2 subs
rm permutations.txt permuts.txt 2>/dev/null
cat subs | uniq | dnsx -a -resp -silent -aaaa -cname -o dnsx_a.txt
cat dnsx_a.txt | sort -u | anew dnsx_resolve.txt
cat dnsx_resolve.txt | awk -F'[][]' '{{print $2}}' | sort -u | anew a-aaaa-dnsx-resp.txt
cat dnsx_resolve.txt | awk -F'[][]' '{{print $1}}' | sort -u | anew cname-dnsx-resp.txt
cat *dnsx-resp.txt subs | sort --random-sort | uniq | anew final_resolvers.txt
mv final_resolvers.txt subs
cat subs | cero -p 443 | sed 's/^*.//' | grep -e "\." | sort -u | anew cero_output.txt
cat subs cero_output.txt | grep -i "$(cat wildcards| sed -z 's/\n/\\|/g;s/,$/\n/' | sed 's/\(.*\)\\|/\1/')" | sort -u > subs2;mv subs2 subs;rm cero_output.txt
cat subs | httpx -p 80,443 -csp-probe -status-code -no-color | anew csp_probed.txt | cut -d ' ' -f1 | unfurl -u domains | anew -q csp_subdomains.txt
cat csp_subdomains.txt subs | grep -i "$(cat wildcards| sed -z 's/\n/\\|/g;s/,$/\n/' | sed 's/\(.*\)\\|/\1/')" | sort -u > subs2;mv subs2 subs
rm csp_probed.txt csp_subdomains.txt
dnsx -r /opt/resolvers.txt -retry 3 -cname -l subs | unfurl domains | sort -u | anew dnsx_cname.txt
cat dnsx_cname.txt subs | grep -i "$(cat wildcards| sed -z 's/\n/\\|/g;s/,$/\n/' | sed 's/\(.*\)\\|/\1/')" | sort -u > subs2;mv subs2 subs;rm dnsx_cname.txt
echo "SUBENUM FINISHED" 
exit
