# tcpserver http controller
Made for fun

### Requirements
* `tcpserver` (in debian `ucspi-tcp` package)
* `dirname`
* `readlink`
* `stat`
* `cat`
* `mktemp`
* `date` (used in log function)
* `file` (`/media` routing in router.rc, can be removed)
* `expr` (used for execution time measuring, disabled by default)

### Usage
* put static html files and dynamic html-shellscripts (`*.rc`) to the `html` directory
* put media files to the `media` directory
* edit case in `router.rc` and add your routing code
* edit `settings.rc`
* mount tmpfs in the `tmp` directory (not needed but recommended)
* start server: `./controller.sh`

### Functions
* **echoText content mime code** send string to the browser
* **printFile file mime code [cache-time] [gzip]** print static file
* **renderFile file mime code** render page and print it
* **log 'message content'** print to console (stderr)

### Variables
* **REQUEST_URI** string
* **GET** string

### Extras
* **shared files** share files via http(s)  
	files to remove: `html/shared`, `router.rc.d/shared.rc`

# HTTPS
**Note: remote ip is always 127.0.0.1 with stunnel accept-connect**
1) install `stunnel4` package
2) make directory for certificates, eg: `/ssl` and `cd /ssl`
3) generate CA certificate: `localhost` is your dns address  
	1) `openssl genrsa -out ./rootCA.key 2048`  
	2) `openssl req -x509 -new -nodes -key ./rootCA.key -sha256 -days 36500 -out ./rootCA.pem -subj '/CN=localhost/O=localhost/OU=localhost'`
4) make `v3.ext` file:  
	```
	authorityKeyIdentifier=keyid,issuer
	basicConstraints=CA:FALSE
	keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
	subjectAltName = @alt_names

	[alt_names]
	DNS.1 = localhost
	```
5) generate server certificate:  
	1) `openssl req -new -newkey rsa:2048 -nodes -keyout ./server.key -subj '/C=SE/ST=None/L=NB/O=localhost/CN=localhost' -out ./server.csr`  
	2) `openssl x509 -req -in ./server.csr -CA ./rootCA.pem -CAkey ./rootCA.key -CAcreateserial -out ./server.crt -days 36500 -sha256 -extfile ./v3.ext`
6) merge server key and certificate for stunnel  
	1) `cat ./server.key ./server.crt > ./server.pem`  
	2) `chmod 600 ./server.pem`
7) configure stunnel:  
	```
	pid = /tmp/.stunnel-localhost.pid

	[localhost]
	accept = 8443
	connect = 8080
	cert = /ssl/server.pem
	```
8) start stunnel: `/etc/init.d/stunnel4 start`
9) start tcpserver-http-controller
10) import `rootCA.pem` into your browser
11) paste in address bar: `https://localhost:8443`