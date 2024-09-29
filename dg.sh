#!/usr/bin/env bash
#
# Date:         28/09/2024
# Description:  Used to display various information about a domain.

# Text Formatting
Tab='\t'
Line='\n'
Section='\033[0;32m'      # Section ([+]) -Green
Heading='\033[0;36m'      # Heading - Cyan
Color_Off='\033[0m'       # Text Reset

usage() {
    { echo -e "Usage: $0 -h <domain> \n -d Subdomain enumeration\n -n HTTP non-secure information\n -s HTTPS information" 1>&2; exit 1; }
}

# General
general_information () {
    # [ General ]
    ipv4_array=$(host ${domain_input} | grep -oP 'has address \K\S+')
    ipv6_array=$(host ${domain_input} | grep -oP 'IPv6 address \K\S+')
    for ipv4 in ${ipv4_array[@]}; do
        host_ipv4_array+=$(host ${ipv4} | grep -oP 'pointer \K\S+')
    done
    ping=$(ping -c 1 ${domain_input} | grep -oP 'time=\K\S+')

    # Output
    echo -e ${Section}[+] ${Heading} General ${Color_Off}
    echo -e ${Tab}Host:${Tab}${Tab}${host_ipv4_array:-'Not Found'}
    for ipv4 in ${ipv4_array[@]}; do
        echo -e ${Tab}IPv4:${Tab}${Tab}${ipv4}
    done
    for ipv6 in ${ipv6_array[@]}; do
        echo -e ${Tab}IPv6:${Tab}${Tab}${ipv6}
    done
    echo -e ${Tab}Response Time:${Tab}${ping}ms
}


# HTTP non-secure 
http_information () {
    # [ HTTP ]
    http_code=$(curl -I -s -o /dev/null -w "%{http_code}" http://${domain_input}/)
    http_version=$(curl -I -s -o /dev/null -w "%{http_version}" http://${domain_input}/)

    # Output
    echo -e ${Line}${Section}[+] ${Heading} HTTP ${Color_Off}
    echo -e ${Tab}URL:${Tab}${Tab}http://${domain_input}/
    echo -e ${Tab}Version:${Tab}${http_version}
    echo -e ${Tab}Code:${Tab}${Tab}${http_code}
  
    # [ HTTP Redirect ]
    if [[ $http_code == 3* ]]; then
        redirect_url=$(curl -I -s -o /dev/null -w "%{redirect_url}" http://${domain_input}/)
        redirect_code=$(curl -I -s -o /dev/null -w "%{http_code}" ${redirect_url})
        http_version=$(curl -I -s -o /dev/null -w "%{http_version}" ${redirect_url})

        # Output
        echo -e ${Line}${Section}[+] ${Heading} HTTP Redirect ${Color_Off}
        echo -e ${Tab}URL:${Tab}${Tab}${redirect_url}
        echo -e ${Tab}Version:${Tab}${http_version}
        echo -e ${Tab}Code:${Tab}${Tab}${redirect_code}
    fi
}


# HTTPS secure 
https_information () {
    # [ HTTPS ]
    http_code=$(curl -I -s -o /dev/null -w "%{http_code}" https://${domain_input}/)
    http_version=$(curl -I -s -o /dev/null -w "%{http_version}" https://${domain_input}/)

    # Output
    echo -e ${Line}${Section}[+] ${Heading} HTTPS ${Color_Off}
    echo -e ${Tab}URL:${Tab}${Tab}https://${domain_input}/
    echo -e ${Tab}Version:${Tab}${http_version}
    echo -e ${Tab}Code:${Tab}${Tab}${http_code}
  
    # [ HTTPS Redirect ]
    if [[ $http_code == 3* ]]; then
        redirect_url=$(curl -I -s -o /dev/null -w "%{redirect_url}" https://${domain_input}/)
        redirect_code=$(curl -I -s -o /dev/null -w "%{http_code}" ${redirect_url})
        http_version=$(curl -I -s -o /dev/null -w "%{http_version}" ${redirect_url})

        # Output
        echo -e ${Line}${Section}[+] ${Heading} HTTPS Redirect ${Color_Off}
        echo -e ${Tab}URL:${Tab}${Tab}${redirect_url}
        echo -e ${Tab}Version:${Tab}${http_version}
        echo -e ${Tab}Code:${Tab}${Tab}${redirect_code}
    fi
}


# Whois
whois_information () {
    # [ Whois Information ]
    registrar_name="$(whois ${domain_input} | grep -oP 'Registrar Name: \K.*')"
    if [[ -z "$registrar_name" ]]; then 
        registrar_name="$(whois ${domain_input} | grep -oP 'Registrar: \K.*')"
    fi
    registrar_url=$(whois ${domain_input} | grep -oP 'Registrar URL: \K\S+')
    whois_ns_array=$(whois ${domain_input} | grep -oP 'Name Server: \K\S+')

    # Output
    echo -e ${Line}${Section}[+] ${Heading} Whois Information ${Color_Off}
    echo -e ${Tab}Registrar:${Tab}${registrar_name}
    echo -e ${Tab}Registrar URL:${Tab}${registrar_url}
    for ns in ${whois_ns_array[@]}; do
        echo -e ${Tab}Name Server:${Tab}${ns}
    done
}


# Subdomain enumeration using Certificate Search: https://crt.sh/
subdomain_enumeration () {
    # [ Subdomain Enumeration ]
    subdomain_array=$(curl -s https://crt.sh/\?q\=\%.${domain_input}\&output\=json | jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u)

    # Output
    echo -e ${Line}${Section}[+] ${Heading} Subdomain Enumeration ${Color_Off}
    for subdomain in ${subdomain_array[@]}; do
        echo -e ${Tab}Domain Found:${Tab}${subdomain}
    done
}

# Gather DNS information using dig
dns_information () {
    # [ DNS ]
    a_record_array=$(dig a +short ${domain_input})
    aaaa_record_array=$(dig aaaa +short ${domain_input})
    # IFS: Ignore the spaces by using only "\n" as the delimiter to store mx into array.
    IFS=$'\n'
    mx_record_array=$(dig mx +short ${domain_input})
    ns_record_array=$(dig ns +short ${domain_input})  

    # Output
    echo -e ${Line}${Section}[+] ${Heading} DNS ${Color_Off}
    for a_record in ${a_record_array[@]}; do
        echo -e ${Tab}A Record:${Tab}${a_record}
    done
    for aaaa_record in ${aaaa_record_array[@]}; do
        echo -e ${Tab}AAAA Record:${Tab}${aaaa_record}
    done
    for mx_record in ${mx_record_array[@]}; do
        echo -e ${Tab}MX Record:${Tab}${mx_record}
    done
    for ns_record in ${ns_record_array[@]}; do
        echo -e ${Tab}NS Record:${Tab}${ns_record}
    done  
}

while getopts ":h:dns" o; do
    case "${o}" in
        h)
            domain_input=${OPTARG}
            general_information
            whois_information
            dns_information
            ;;
        d)
            subdomain_enumeration
            ;;
        n) 
            http_information
            ;;
        s)
            https_information
            ;;
        *)
            usage
            ;;
    esac
done
