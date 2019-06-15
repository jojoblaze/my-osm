


## Install the Azure Resource Manager modules from the PowerShell Gallery

Install-Module -Name AzureRM -AllowClobber


# show log extension scripts

sudo cat /var/lib/waagent/custom-script/download/0/stdout

sudo cat /var/lib/waagent/custom-script/download/0/stderr

sudo cat /var/log/azure/custom-script/handler.log


# troubleshooting

sudo cat /var/log/syslog