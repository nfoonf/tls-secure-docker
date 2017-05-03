SCRIPTPATH=${BASH_SOURCE[0]}
ABS_SCRIPTPATH=$(readlink -f $SCRIPTPATH)
BASEDIR=$(dirname $ABS_SCRIPTPATH)
export DIR=$BASEDIR/files
alias docker='docker --tlsverify --tlscacert=$DIR/ca.pem --tlscert=$DIR/client_cert.pem --tlskey=$DIR/client_key.pem'
alias docker-compose='docker-compose --tlsverify --tlscacert=$DIR/../ca/ca.pem --tlscert=$DIR/client_cert.pem --tlskey=$DIR/client_key.pem'

