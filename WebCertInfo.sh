#!/bin/bash

Version="1.7"

#Today=$(date "+%b %d %Y")

HasPipe=""
#handle piping
if readlink /proc/$$/fd/0 | grep -q "^pipe:"; then
	HasPipe="pipe"
fi

Help()
{
	local Script=$1
	local Host="$2"
	local Port="$3"
	local Call
	Script="${Script##*/}"
	Script="${Script%.*}"

	if [ -z "${Host}" ] && [ -z "${Port}" ]; then
		Call="${Script} <host> <port>"
	else
		Call="${Script} ${Host} ${Port}"
	fi

	echo "Command: ${Script}"
	echo "Version: ${Version}"
	echo "Purpose: pull the certificate from a given web service"
	echo ""
	echo -e "Usage:\t${Call} <arguments>"
	echo -e "\t${Call} all\t\t: Get ALL Cert Data"
	echo -e "\t${Call} alias\t\t: Get Cert Alias"
	echo -e "\t${Call} basic\t\t: Get Basic Cert output"
	echo -e "\t${Call} email\t\t: Get Cert email"
	echo -e "\t${Call} serial\t\t: Get Cert Serial"
	echo -e "\t${Call} subject\t\t: Get Cert Subject"
	echo -e "\t${Call} date\t\t: Get Issued and Exired Date"
	echo -e "\t${Call} date-issue\t: Get Issued Date"
	echo -e "\t${Call} issued\t\t: Get Issued Date"
	echo -e "\t${Call} check-expired\t: Check if certificate is past expired date"
	echo -e "\t${Call} date-expired\t: Get Expired Date"
	echo -e "\t${Call} expire\t\t: Get Expired Date"
	echo -e "\t${Call} issuer\t\t: Get Issuer"
	echo -e "\t${Call} san\t\t: Get SANs"
	echo -e "\t${Call} fingerprint\t: Get Fingerprint"
	echo -e "\t${Call} --help\t: This Page"
}

GetCertData()
{
	local HostAndPort=$1
	local Type=$2
	openssl s_client -connect ${HostAndPort} < /dev/null 2> /dev/null | ParseCertData "${Type,,}"
}

ParseCertData()
{
	local Type=$1
	case ${Type,,} in
		all)
			cat /dev/stdin | openssl x509 -noout -text 2> /dev/null
			;;
		alias)
			cat /dev/stdin | openssl x509 -noout -text 2> /dev/null
			;;
		email)
			cat /dev/stdin | openssl x509 -noout -email 2> /dev/null
			;;
		serial)
			cat /dev/stdin | openssl x509 -noout -seral 2> /dev/null | sed "s/serial=//g" 2> /dev/null
			;;
		subject)
			cat /dev/stdin | openssl x509 -noout -subject 2> /dev/null | sed "s/subject= \///g" | sed "s/subject=//g" | sed "s/\//, /g" 2> /dev/null
			;;
		date|dates)
			cat /dev/stdin | openssl x509 -noout -dates 2> /dev/null | egrep "^notBefore|^notAfter" | sed "s/notBefore=/Start=/g" | sed "s/notAfter=/Expire=/g" | sed "s/ ..:..:..//g" | sed "s/  / /g" | cut -d ' ' -f 1,2,3,4
			;;
		issued|date-issued)
			cat /dev/stdin | openssl x509 -noout -startdate 2> /dev/null | sed "s/notBefore=//g" | sed "s/ ..:..:..//g" | sed "s/  / /g" | cut -d ' ' -f 1,2,3
			;;
		expire|date-expired)
			cat /dev/stdin | openssl x509 -noout -dates 2> /dev/null | grep ^notAfter | sed "s/notAfter=//g" | sed "s/ ..:..:..//g" | sed "s/  / /g" | cut -d ' ' -f 1,2,3
			;;
		check-expire)
			ExpireDate=$(cat /dev/stdin | openssl x509 -noout -dates 2> /dev/null | grep ^notAfter | sed "s/notAfter=//g" | sed "s/ ..:..:..//g" | cut -d ' ' -f 1,2,3)
			local cMonth=$(echo ${ExpireDate} | cut -d ' ' -f 1)
			local cDay=$(echo ${ExpireDate} | cut -d ' ' -f 2)
			local cYear=$(echo ${ExpireDate} | cut -d ' ' -f 3)
			local tMonth=$(date "+%b")
			local tDay=$(date "+%d")
			local tYear=$(date "+%Y")

			if [ ${cYear} -eq ${tYear} ]; then
				cMonthN=$(echo ${cMonth} | sed "s/Jan/01/g" | sed "s/Feb/02/g" | sed "s/Mar/03/g" | sed "s/Apr/04/g" | sed "s/May/05/g" | sed "s/Jun/06/g" | sed "s/Jul/07/g" | sed "s/Aug/08/g" | sed "s/Sep/09/g" | sed "s/Oct/10/g" | sed "s/Nov/11/g" | sed "s/Dec/12/g")
				tMonthN=$(echo ${tMonth} | sed "s/Jan/01/g" | sed "s/Feb/02/g" | sed "s/Mar/03/g" | sed "s/Apr/04/g" | sed "s/May/05/g" | sed "s/Jun/06/g" | sed "s/Jul/07/g" | sed "s/Aug/08/g" | sed "s/Sep/09/g" | sed "s/Oct/10/g" | sed "s/Nov/11/g" | sed "s/Dec/12/g")
				if [ ${cMonthN} -le ${tMonthN} ]; then
					echo ${cMonthN} -ge ${tMonthN}
					if [ ${cDay} -le ${tDay} ]; then
						echo "expired"
					else
						echo "valid"
					fi
				else
					echo "valid"
				fi
			elif [ ${cYear} -lt ${tYear} ]; then
				echo "expired"
			else
				echo "valid"
			fi

			;;
		issuer)
			cat /dev/stdin | openssl x509 -noout -issuer 2> /dev/null | sed "s/issuer= //g" | sed "s/issuer=//g" 2> /dev/null | sed "s/ = /=/g" | sed "s/\//, /g" 2> /dev/null
			;;
		fingerprint)
			cp /dev/stdin /tmp/crtData
			cat /tmp/crtData | openssl x509 -noout -fingerprint 2> /dev/null | sed "s/ Fingerprint//g" 2> /dev/null
			cat /tmp/crtData | openssl x509 -noout -sha256 -fingerprint 2> /dev/null | sed "s/ Fingerprint//g" 2> /dev/null
			rm /tmp/crtData
			;;
		san|sans)
			cat /dev/stdin | openssl x509 -noout -text 2> /dev/null | grep DNS: | tr -d ' ' | tr -d '\t'
			;;
		basic)
			cp /dev/stdin /tmp/crtData
			cat /tmp/crtData | openssl x509 -noout -alias -email -subject -dates -issuer 2> /dev/null
			cat /tmp/crtData | openssl x509 -noout -fingerprint 2> /dev/null
			cat /tmp/crtData | openssl x509 -noout -sha256 -fingerprint 2> /dev/null
			local SANs=$(cat  /tmp/crtData | ParseCertData "sans")
			if [ ! -z "${SANs}" ]; then
				echo "SANs=${SANs}"
			fi
			rm /tmp/crtData
			;;
		*)
			;;
	esac
}

if [ ! -z "${HasPipe}" ]; then
	Type=$1
	ParseCertData ${Type}
else
	case $# in
		1)
			host=$1
			port="443"
			Type="--help"
			;;
		2)
			host=$1
			port="443"
			Type=$2
			;;
		*)
			host=$1
			port=$2
			Type=$3
#			Action=$4
			;;
	esac

	if [ ! -z "${host}" ] && [ ! -z "${port}" ]; then
		case ${Type} in
			--help|help)
				Help $0 ${host} ${port}
				;;
			*)
				GetCertData ${host}:${port} ${Type}
				;;
		esac
	else
		Help $0 ${host} ${port}
	fi
fi
