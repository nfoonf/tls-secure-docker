# script for generation of a new ca-key
# only run once

openssl genrsa -aes256 -out ca/ca-key.pem 4096
openssl req -new -x509 -days 365 -key ca/ca-key.pem -sha256 -out ca/ca.pem

