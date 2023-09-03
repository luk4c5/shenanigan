# Shenanigan
Shenanigan is an incredibly ugly bash script designed to load balance recon and vulnerability scanning workflows across multiple machines via SSH. 

# Deploy 
Put the ssh private key in /root/.ssh/id_rsa and give it the right permissions, then put the public key in all the servers you want to use in /root/.ssh/authorized_keys.
After that, place the ip of the servers in /root/shenanigan/servers.txt, install tools and workflows with --install and hack the planet. 

# Warnings 
--install currently only supports Ubuntu/Debian 
Be ready to face a lot of bugs, I'm not being modest, YOU'RE GOING to face a LOT of bugs. 

# Usage
```
--help - > Self explanatory 
--install servers.txt - > Install tools and default workflows
--everything rootdomains - > Will perform subdomain enumeration, probing and vulnerability scanning.    
--subenum rootdomains - > Self explanatory  
--nuclei httpx.txt - > Self explanatory 
--probing hosts.txt - > Self explanatory 
```
# Example
```
--subenum rootdomains 
--probing subs 
--nuclei httpx.txt 
cat navgix.out nuc.out 
```
