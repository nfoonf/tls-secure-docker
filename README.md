# tls-secure-docker

## 1. Introduction

This collection of scripts allows to easily configure a dockerd and a client to use encrypted and authorized communications between them and therefore makes using docker way more secure.

## 2. Generating Certificates and Keys
As a first step we have to generate several certificates and keys which are used in different places to ensurce secure communication. This chapter shows, how to do this.

### 2.1 CA
the first step is to generate a CA-File which is used to generate further certificates. In order to do so we run the script `ca.sh`:

```
$ sh ca.sh
Generating RSA private key, 4096 bit long modulus
.......................++
..........................................................................++
e is 65537 (0x10001)
Enter pass phrase for ca/ca-key.pem:
Verifying - Enter pass phrase for ca/ca-key.pem:
Enter pass phrase for ca/ca-key.pem:
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:
State or Province Name (full name) []:
Locality Name (eg, city) [Default City]:
Organization Name (eg, company) [Default Company Ltd]:
Organizational Unit Name (eg, section) []:
Common Name (eg, your name or your server's hostname) []:
Email Address []:
$

```

this generates the CA private key and the CA certificate which we use on the client and server. We have to give the CA-Key a Password _which we have to remember during further steps_ .
### 2.2 Server
Next we have to generate server keys for dockerd. Again, we have to execute a script, 'server-key.sh' this time:
```
$ sh server-key.sh
Generating RSA private key, 4096 bit long modulus
................................................................++
........................................................................++
e is 65537 (0x10001)
Signature ok
subject=/CN=c4-docker-worker-01
Getting CA Private Key
Enter pass phrase for ca/ca-key.pem:
$
```
In the folder `engine_keys` you can now find Key and ceritificate used by the docker engine.
### 2.3 Client
Last, we have to generate the keys and certs used by docker and docker-compose or any other service which uses the docker api.
For this we execute `client.sh`:

```
$ sh client.sh
Generating RSA private key, 4096 bit long modulus
.................................................................++
e is 65537 (0x10001)
Signature ok
subject=/CN=client
Getting CA Private Key
Enter pass phrase for ca/ca-key.pem:
$
```

in the folder `files` you can now find all files that are used by a consumer of the docker-api

## 3. Configuring dockerd

to use the certs with docker you have to copy the contents of `engine_keys` onto the docker host, preferable into the directory /etc/docker/engine_keys.
After this you have to modify the startup of dockerd in order to use these keys. For this we edit the systemd service file. An example of such an edit can be seen below:

```
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target docker.socket firewalld.service
Requires=docker.socket

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd --tlsverify --tlscacert=/etc/docker/engine_keys/ca.pem --tlscert=/etc/docker/engine_keys/docker1-cert.pem --tlskey=/etc/docker/engine_keys/docker1-key.pem -H=0.0.0.0:2376
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=1048576
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process

[Install]
WantedBy=multi-user.target
```
the only line we edit is the line beginning with `ExecStart`. Everything else can stay the way it was. After that we have to reload the systemd config with `systemctl daemon-reload` and then restart docker: 'systemctl restart docker'. We now have a docker engine listening on Port 2376 and only accepting clients with valid certificates.

## 4. Configuring the Client
Next we have to configure docker commandline tools for using the client certs. For this we have to copy the file `alias.sh` and the folder `files` onto the host we want to speak with the docker daemon.
### 4.1 Setting environment variables and sourcing files
Once this is finished we have to source the file `alias.sh`. Source executes the commands in the file as they were executed in the current shell. The changes made therefore are not permanent and are discarded as soon as we close the shell:
```
$ source alias.sh
$ alias
alias docker='docker --tlsverify --tlscacert=$DIR/ca.pem --tlscert=$DIR/client_cert.pem --tlskey=$DIR/client_key.pem'
alias docker-compose='docker-compose --tlsverify --tlscacert=$DIR/../ca/ca.pem --tlscert=$DIR/client_cert.pem --tlskey=$DIR/client_key.pem'

```
this means, if we type `docker` in this shell from now on, we instead execute docker with all commandline-settings necessary to talk to the docker daemon.

As the last step we have to set the environment variable `$DOCKER_HOST` onto the location of the docker daemon:
```
$ export DOCKER_HOST=85.84.49.45:2376
```

With this our setup is finished and we can talk to a remote docker engine in a secure way:

```
$ docker run hello-world

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://cloud.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/engine/userguide/
```
