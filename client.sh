cp ca/ca.pem files/ca.pem

openssl genrsa -out files/client_key.pem 4096
openssl req -subj '/CN=client' -new -key files/client_key.pem -out files/client.csr
echo extendedKeyUsage = clientAuth > files/extfile_client.cnf
openssl x509 -req -days 365 -sha256 -in files/client.csr -CA ca/ca.pem -CAkey ca/ca-key.pem -CAcreateserial -out files/client_cert.pem -extfile files/extfile_client.cnf

