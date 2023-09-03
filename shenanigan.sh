#!/bin/bash
figlet "Shenanigan" -k



function tools {
    ssh="ssh $1 -i /root/.ssh/id_rsa"
    echo "Installing everything now" 
    $ssh "apt-get -y update"
    $ssh "apt-get -y install sudo zip wget curl make build-essential git jq unzip libpcap-dev python3 python3-pip python2 whois"
    scp -i /root/.ssh/id_rsa subenum.sh $1:/usr/bin/subenum
    scp -i /root/.ssh/id_rsa probe.sh $1:/usr/bin/probe
    scp -i /root/.ssh/id_rsa nuc.sh $1:/usr/bin/nuc
    $ssh "mkdir /root/scans/"
    $ssh "chmod +x /usr/bin/subenum;chmod +x /usr/bin/probe;chmod +x /usr/bin/nuc"
    $ssh "wget https://dl.google.com/go/go1.20.3.linux-amd64.tar.gz;rm -rf /usr/local/go && tar -C /usr/local -xzf go1.20.3.linux-amd64.tar.gz;echo 'export PATH=$PATH:/usr/local/go/bin:/root/go/bin/' >> ~/.bashrc;source ~/.bashrc;go version"
    $ssh "echo IyEvYmluL2Jhc2gKY3VybCAtcyBodHRwczovL2NydC5zaC9cP3FcPVwlLiQxXCZvdXRwdXRcPWpzb24gfCBqcSAtciAnLltdLm5hbWVfdmFsdWUnIHwgc2VkICdzL1wqXC4vL2cnIHwgc29ydCAtdQo= | base64 -d > /opt/crt.sh;chmod +x /opt/crt.sh"
    $ssh "curl https://wordlists-cdn.assetnote.io/data/manual/best-dns-wordlist.txt -o /opt/assetnote.txt"
    $ssh "curl https://raw.githubusercontent.com/BonJarber/fresh-resolvers/main/resolvers.txt -o /opt/resolvers.txt"
    $ssh "git clone https://github.com/blechschmidt/massdns;cd massdns;make;mv ./bin/massdns /usr/bin/"
    $ssh "go install github.com/d3mondev/puredns/v2@latest"
    $ssh "go install github.com/tomnomnom/waybackurls@latest"
    $ssh "go install -v github.com/tomnomnom/anew@latest"
    $ssh "go install github.com/tomnomnom/unfurl@latest"
    $ssh "go install github.com/bp0lr/gauplus@latest"
    $ssh "wget https://github.com/Findomain/Findomain/releases/download/8.2.1/findomain-linux.zip;unzip findomain-linux.zip;chmod +x findomain;mv findomain /usr/bin/"
    $ssh "go install github.com/tomnomnom/assetfinder@latest"
    $ssh "go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
    $ssh "mkdir /root/.config/;mkdir /root/.config/subfinder/"
    $ssh "go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest"
    $ssh "go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
    $ssh "go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest"
    $ssh "echo subfinderproviderconfigb64| base64 -d > /root/.config/subfinder/provider-config.yaml"
    $ssh "go install github.com/Josue87/gotator@latest"
    $ssh "GO111MODULE=on go install github.com/jaeles-project/gospider@latest"
    $ssh "go install github.com/lc/gau/v2/cmd/gau@latest"
    $ssh "go install -v github.com/owasp-amass/amass/v4/...@master"
    $ssh "go install github.com/glebarez/cero@latest"
    $ssh "git clone https://github.com/hakaioffsec/navgix;cd navgix; go get .; go build .; mv navgix /usr/bin/"
    $ssh "go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"
    $ssh "nuclei"
    echo "everything ready at: $1"
}

function install {

    for ip in $(cat $1) 
    do
        tools $ip &
    done
}

function splitthings {
        
        if [[ $(cat $1 | wc -l) -gt $(cat /root/shenanigan/servers.txt | wc -l) ]] # if the number of domains is greater than the number of servers 
        then
            domains=$(cat $1 | wc -l)
            servers=$(cat /root/shenanigan/servers.txt | wc -l)
            if [ "$(( $domains % servers ))" -eq 0 ] # if the division of the number of domains by the number of servers gives a remainder of 0, do domains / servers 
                then
                    files=$((domains / servers))
                    split -l $files $1 -d $2
                    tasks=$(cat /root/shenanigan/servers.txt | sort --random-sort | uniq)
                    tasks_file=$(echo /tmp/$RANDOM)
                    echo $tasks | tr ' ' '\n' > $tasks_file
                else
                    files=$(( ($domains + $servers - 1) / $servers )) # basic math to get rid of the remainder 
                    split -l $files $1 -d $2
                    tasks=$(cat /root/shenanigan/servers.txt | sort --random-sort | uniq)
                    tasks_file=$(echo /tmp/$RANDOM)
                    echo $tasks | tr ' ' '\n' > $tasks_file
                fi
        fi

        if [[ $(cat $1 | wc -l) -lt $(cat /root/shenanigan/servers.txt | wc -l) ]]
        then
            tasks=$(cat /root/shenanigan/servers.txt | sort --random-sort | uniq | head -n `cat $1 | wc -l`) 
            tasks_file=$(echo /tmp/$RANDOM)
            echo $tasks | tr ' ' '\n' > $tasks_file
            split -l 1 $1 -d $2
        fi


        if [[ $(cat $1 | wc -l) -eq `cat /root/shenanigan/servers.txt | wc -l` ]]
        then    
                split -l 1 $1 -d $2
                tasks=$(cat /root/shenanigan/servers.txt | sort --random-sort | uniq)
                tasks_file=$(echo /tmp/$RANDOM)
                echo $tasks | tr ' ' '\n' > $tasks_file
        fi

}

function vulnscan {
    figlet "Vuln Scanning Started" -k
    readarray -t ssh_ips < /root/shenanigan/servers.txt
    echo "Spliting httpx.txt to load balance nuclei across $(cat /root/shenanigan/servers.txt | wc -l) servers"
    path=$(echo $PWD/nucrei/)
    mkdir nucrei;cd nucrei;mv ../$1 $path;splitthings $1 targets
    num_servers=${#ssh_ips[@]}
    domain_files=(targets*)
    ls -lah | grep -i domains
    for ((i = 0; i < ${#domain_files[@]}; i++)); do
        domain_file=${domain_files[$i]}
        cd $path;
        ssh_ip=${ssh_ips[$((i % num_servers))]}
        recon_dir=$(echo nuclei$scanid)
        echo "Transferring $domain_file to $ssh_ip..."
        ssh -i /root/.ssh/id_rsa root@$ssh_ip "mkdir /root/scans/$recon_dir/"
        scp -i /root/.ssh/id_rsa "$domain_file" root@$ssh_ip:/root/scans/$recon_dir/wildcards
        nohup ssh -i /root/.ssh/id_rsa root@$ssh_ip "cd /root/scans/$recon_dir/;nuc >/dev/null" &
        echo "Vuln Scanning on $ssh_ip started" 
        cat $domain_file | head -n20
        cd ../;
    done
}

function subenum {
    readarray -t ssh_ips < $2
    figlet "Subenum Started" -k 
    num_servers=${#ssh_ips[@]}
    domain_files=($1*)
    ls -lah | grep -i $1
    for ((i = 0; i < ${#domain_files[@]}; i++)); do
        domain_file=${domain_files[$i]}
        ssh_ip=${ssh_ips[$((i % num_servers))]}
        recon_dir=$(echo subenum$scanid)
        echo "Transferring $domain_file to $ssh_ip..."
        ssh -i /root/.ssh/id_rsa root@$ssh_ip "mkdir /root/scans/$recon_dir/"
        scp -i /root/.ssh/id_rsa "$domain_file" root@$ssh_ip:/root/scans/$recon_dir/wildcards
        nohup ssh -i /root/.ssh/id_rsa root@$ssh_ip "cd /root/scans/$recon_dir/;subenum" &
        echo "Recon on $ssh_ip started on the following domains" 
        cat $domain_file
    done
}


function retrieve_probes {

    servers=$(cat $1 | wc -l)
    while true; do
        notifications=$(grep "PROBE FINISHED" nohup.out | wc -l)

        if [ $notifications -eq $servers ]; then
            break
        fi

        sleep 30
    done

    echo "Probing finished."
    for ip in $(cat $1 | sort --random-sort | uniq);do 
        echo "Transferring /root/scans/probes$scanid from $ip to probes/probes$ip" 
        ssh -i /root/.ssh/id_rsa root@$ip "cat /root/scans/probes$scanid/httpx.*" >> httpx.txt  2>/dev/null
        ssh -i /root/.ssh/id_rsa root@$ip "cat /root/scans/probes$scanid/naabu.*" >> naabu.txt  2>/dev/null
    done


    echo "httpx.txt done"
    echo "naabu.txt done"
}

function retrieve_subenum {

    servers=$(cat $1 | wc -l)
    while true; do
        notifications=$(grep "SUBENUM FINISHED" nohup.out | wc -l)

        if [ $notifications -eq $servers ]; then
            break
        fi

        sleep 30
    done

    echo "Subdomain Enumeration Finished."
    for ip in $(cat $1 | sort --random-sort | uniq);do 
        echo "Transferring /root/scans/subenum$scanid from $ip to subenum/subenum$ip" 
        ssh -i /root/.ssh/id_rsa root@$ip "cat /root/scans/subenum$scanid/subs.*" >> subs  2>/dev/null
    done

    echo "subs done"
}



function retrieve_bugs   {

    servers=$(cat $1 | wc -l)
    while true; do
        notifications=$(grep "SCAN FINISHED" nohup.out | wc -l)

        if [ $notifications -eq $servers ]; then
            break
        fi

        sleep 30
    done

    figlet "Vulnerability Scanning Finished" -k 
    mkdir nuclei/
    for ip in $(cat /root/shenanigan/servers.txt | sort --random-sort | uniq);do 
        echo "Transferring /root/scans/nuclei$scanid from $ip to nuclei/nuclei$ip" 
        ssh -i /root/.ssh/id_rsa root@$ip "cat /root/scans/nuclei$scanid/nuc.*" >> nuc.out  2>/dev/null
        ssh -i /root/.ssh/id_rsa root@$ip "cat /root/scans/nuclei$scanid/navgix.*" >> navgix.out  2>/dev/null
    done

    echo "nuc.out done"
    echo "navgix.out done"
}



function probing {
    readarray -t ssh_ips < $2
    figlet "Probing Phase Started" -k 
    num_servers=${#ssh_ips[@]}
    domain_files=($1*)
    ls -lah | grep -i $1
    for ((i = 0; i < ${#domain_files[@]}; i++)); do
        domain_file=${domain_files[$i]}
        ssh_ip=${ssh_ips[$((i % num_servers))]}
        recon_dir=$(echo probes$scanid)
        echo "Transferring $domain_file to $ssh_ip..."
        ssh -i /root/.ssh/id_rsa root@$ssh_ip "mkdir /root/scans/$recon_dir/"
        scp -i /root/.ssh/id_rsa "$domain_file" root@$ssh_ip:/root/scans/$recon_dir/wildcards
        nohup ssh -i /root/.ssh/id_rsa root@$ssh_ip "cd /root/scans/$recon_dir/;probe" &
        echo "Probing on $ssh_ip started on the following domains:" 
        cat $domain_file | head -n20
    done
}


scanid=$(echo $RANDOM)

if [ ! -f /root/shenanigan/servers.txt ]; then
    echo "Servers not properly configured"
fi
if [ "$#" -eq 0 ]
then
  cat << 'EOF'
  
USAGE: 
--help - > Self explanatory 
--install servers.txt - > Install tools and default workflows
--everything rootdomains - > Will perform subdomain enumeration, probing and vulnerability scanning.    
--subenum rootdomains - > Self explanatory  
--nuclei httpx.txt - > Self explanatory 
--probing hosts.txt - > Self explanatory 

EXAMPLE:
--subenum rootdomains 
--probing subs 
--nuclei httpx.txt 
cat navgix.out nuc.out 
EOF
  exit 1
fi

if [ "$1" == "--help" ];
then 
        cat << 'EOF'

USAGE: 
--help - > Self explanatory 
--install servers.txt - > Install tools and default workflows
--everything rootdomains - > Will perform subdomain enumeration, probing and vulnerability scanning.    
--subenum rootdomains - > Self explanatory  
--nuclei httpx.txt - > Self explanatory 
--probing hosts.txt - > Self explanatory 

EXAMPLE:
--subenum rootdomains 
--probing subs 
--nuclei httpx.txt 
cat navgix.out nuc.out 
EOF
    exit 1
fi


if [ "$1" == "--everything" ];
then
    splitthings $2 domains
    subenum domains $tasks_file
    retrieve_subenum $tasks_file
    cat allsubs | sort --random-sort | uniq > t;mv t subs
    splitthings subs allsubs
    probing allsubs /root/shenanigan/servers.txt
    retrieve_probes /root/shenanigan/servers.txt
    vulnscan httpx.txt 
    retrieve_bugs /root/shenanigan/servers.txt
fi

if [ "$1" == "--probing" ];
then
    splitthings $2 domains
    probing domains $tasks_file
    retrieve_probes $tasks_file
fi

if [ "$1" == "--subenum" ];
then
    splitthings $2 domains
    subenum domains $tasks_file
    retrieve_subenum $tasks_file
fi

if [ "$1" == "--nuclei" ];
then
     vulnscan $2
     echo /root/scans/nuclei$scanid
     retrieve_bugs /root/shenanigan/servers.txt
fi


if [ "$1" == "--install" ];
then
    install $2
fi

