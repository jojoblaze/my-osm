


## Install the Azure Resource Manager modules from the PowerShell Gallery

Install-Module -Name AzureRM -AllowClobber


# show log extension scripts

sudo cat /var/lib/waagent/custom-script/download/0/stdout

sudo cat /var/lib/waagent/custom-script/download/0/stderr

sudo cat /var/log/azure/custom-script/handler.log


# troubleshooting

sudo cat /var/log/waagent.log 


sudo cat /var/log/syslog





## Azure ARM images

# Ubuntu

Publisher: Canonical

Offer: UbuntuServer

SKU: 18.04-LTS

Version: latest


# Debian

Publisher: credativ

Offer: Debian

SKU: 8, 8-backports, 9, 9-backports

Version: latest or a valid version