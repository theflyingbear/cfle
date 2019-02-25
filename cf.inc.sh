#!/bin/bash


function extract_result_id() {
	python -c "import sys, json; print json.load(sys.stdin)['result'][0]['id']" 2> /dev/null
}

#split domain name into local+domaine.tld
function retrieve_domain_and_record_name() {
 local domain="$1"

 d=$(echo ${domain} | awk -F'.' '{ print $(NF -1)"."$NF }')

 i=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${d}&status=active&page=1&per_page=20&order=status&direction=desc&match=all" \
     -H "X-Auth-Email: ${CFAUTHEMAIL}" \
     -H "X-Auth-Key: ${CFAUTHKEY}" \
     -H "Content-Type: application/json" | json_pp | extract_result_id)

 echo "_acme-challenge.${domain}:${i}"
}

# special cases like .co.uk - not implemented
function retrieve_special_tlds_case() {
 local subdomain="$1"
 local domain="$2"

}

# retrieve name servers of the domain and check dns record presence
function check_if_record_is_deployed() {
 local domain="$1"
 local record="$2"
 local token="$3"

 while true ; do
  f=$(mktemp -u)
  host -t TXT ${record} 1.1.1.1 2>&1 | grep "text" | awk -F'"' '{ print $2 }' > ${f}
  if [ $(wc -l ${f} | awk '{ print $1 }') -gt 1 ] ; then
   echo "  + more than one record found"
  fi
  grep -- ${token} ${f} &> /dev/null
  if [ $? -ne 0 ] ; then
   rm -f ${f}
   echo "  + token '${token}' not found in ${record} - wait 10sec"
   sleep 10
  else
   rm -f ${f}
   echo "  + record found, with apropriate token"
   break
  fi
 done
}

# refresh dns zone
function refresh_dns_zone() {
 local domain="$1"
 # nothing to do here with CF
}

# create TXT record for the ACME challenge
function create_txt_record() {
 local domain="$1"
 local foo="$2"
 local token="$3"

 tmp=$(retrieve_domain_and_record_name ${domain})
 CFZONEID=$(echo ${tmp} | cut -d':' -f2)
 record=$(echo ${tmp} | cut -d':' -f1)

 curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${CFZONEID}/dns_records" \
  -H "X-Auth-Email: ${CFAUTHEMAIL}" \
  -H "X-Auth-Key: ${CFAUTHKEY}" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"TXT\",\"name\":\"${record}\",\"content\":\"${token}\",\"ttl\":120,\"priority\":1,\"proxied\":false}" &> /dev/null

 refresh_dns_zone ${domain}

 check_if_record_is_deployed ${domain} ${record} ${token}
}

# delete TXT record of the ACME challenge
function delete_txt_record() {
 local domain="$1"
 local foo="$2"
 local token="$3"

 tmp=$(retrieve_domain_and_record_name ${domain})
 CFZONEID=$(echo ${tmp} | cut -d':' -f2)
 record=$(echo ${tmp} | cut -d':' -f1)

 cfrecordid=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CFZONEID}/dns_records?type=TXT&name=${record}&content=${token}&page=1&per_page=20&order=type&direction=desc&match=all" \
  -H "X-Auth-Email: ${CFAUTHEMAIL}" \
  -H "X-Auth-Key: ${CFAUTHKEY}" \
  -H "Content-Type: application/json" | json_pp | extract_result_id)
 curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${CFZONEID}/dns_records/${cfrecordid}" \
  -H "X-Auth-Email: ${CFAUTHEMAIL}" \
  -H "X-Auth-Key: ${CFAUTHKEY}" \
  -H "Content-Type: application/json" &> /dev/null

 refresh_dns_zone ${d}
}

# deploy cert
function deploy_cert() {
 local domain="$1"
 local privkey="$2"
 local pubkey="$3"
 local fullchain="$4"
 local chain="$5"
 local timestamp="$6"
 echo " + ssl_certificate: ${fullchain}"
 echo " + ssl_cert_key   : ${privkey}"
}

function unchanged_cert() {
 echo " + Certificate is still valid : done."
}

function invalid_challenge() {
 echo " + Challenge was invalid : take a look."
}

function request_failure() {
 echo " + Request to LE failed, exiting hook."
}



# EOF
