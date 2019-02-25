#!/bin/bash

#set -x
umask 027

. hooks/cfle/cf.cfg.sh
. hooks/cfle/cf.inc.sh

if [ $# -lt 1 ] ; then
    echo "Usage: $0 action param1 ... paramN"
    exit 1
fi

hookaction="$1"
shift

case "${hookaction}" in
    deploy_challenge)
        create_txt_record "$@"
        ;;
    clean_challenge)
        delete_txt_record "$@"
        ;;
    deploy_cert)
        deploy_cert "$@"
        ;;
    unchanged_cert)
        unchanged_cert "$@"
        ;;
    invalid_challenge)
        invalid_challenge "$@"
        ;;
    request_failure)
        request_failure "$@"
        ;;
	startup_hook|exit_hook|deploy_ocsp|generate_csr)
        ;;
	*) # ignore invalid hooks
        ;;
esac

# EOF
