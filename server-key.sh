# script for generation of Server Keys for Docker Engine
# start this script, deploy all keys on the Systems running the Docker-Engines.
# after that edit the Systemd Script. run 'systemd daemon reload' and 'systemd restart docker'
echo "set your CN and subjectAltName IP in the file"
openssl genrsa -out engine_keys/docker1-key.pem 4096
openssl req -subj "/CN=SETYOURHOSTNAMEHERE" -sha256 -new -key engine_keys/docker1-key.pem -out engine_keys/docker1.csr
echo subjectAltName = IP:SET_YOUR_HOST-IP_HERE,IP:127.0.0.1 > engine_keys/extfile_docker1.cnf
openssl x509 -req -days 365 -sha256 -in engine_keys/docker1.csr -CA ca/ca.pem -CAkey ca/ca-key.pem -CAcreateserial -out engine_keys/docker1-cert.pem -extfile engine_keys/extfile_docker1.cnf

