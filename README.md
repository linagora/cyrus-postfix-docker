# yadd/cyrus-imapd-postfix

Docker image based on last Debian stable release. It embeds:
 * postfix
 * cyrus-imapd (backports version)

## HOW TO START
```
docker build -t cyrus-local .
docker-compose up -d
```
- Remote into the docker and manually add user/ start SASLDB
```
# Start saslthdb
/etc/init.d/saslauthd start
```
### Create Mailbox user/password in SASLAUTHDB
```
echo 'createmailbox user.example@localhost.com' | cyradm -u cyrus -w cyrus localhost
echo 'createmailbox user.ana@localhost.com' | cyradm -u cyrus -w cyrus localhost
echo 'createmailbox user.bob@localhost.com' | cyradm -u cyrus -w cyrus localhost
echo 'example' | saslpasswd2 -p -c example
echo 'example' | saslpasswd2 -p -c ana
echo 'example' | saslpasswd2 -p -c bob
```
### List user in SASLAUTHDB and verify password
```
sasldblistusers2
cyrus@ca77a55b1057: userPassword
example@ca77a55b1057: userPassword
testsaslauthd -u example -p example -f /var/run/saslauthd/mux
0: OK "Success."
```
### Sample CURL
```
curl -X POST      -H "Content-Type: application/json"      -H "Accept: application/json"      --user example:example      -d '{
       "using": [ "urn:ietf:params:jmap:core", "urn:ietf:params:jmap:mail" ],
       "methodCalls": [[ "Mailbox/get", {}, "c1" ]]
     }'      http://localhost:8008/jmap/ | jq
```
## Environment variables

Changing these variables has no effect when /etc/postfix is populated
_(after the first run if volume is kept)_.

Environment variables for Postfix _(with default value)_:

* For Cyrus-Imapd:
  * `CYRUS_PWD` = `""` _(if not set, cyradm isn't usable)_
  * `SASL_PWCHECK_METHOD` = `saslauthd auxprop`
  * `SASLDB` = `sasldb`
* For Postfix
  * `MAILNAME` = `mail.example.com`
  * `OTHER_DESTINATIONS` = `example.com mail.example.com`
  * `RELAY_HOST` = `""`
  * `MYNETWORKS` = `127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128`
  * `ROOT_ADDRESS` = `""`: _(address to which mail from root and postmaster will be sent)_

## Exposed ports

* Postfix _(depends on configuration)_:
  * 25
  * 465 _(not configured by default)_
  * 587 _(not configured by default)_
* Cyrus _(depends on configuration)_:
  * 110
  * 143
  * 993
  * 995 _(not configured by default)_
  * 2000 _(not configured by default)_
  * 8008
  * 8443 _(not configured by default)_

## Repository and bug reports

* Repository: [github.com/guimard/cyrus-postfix-docker](https://github.com/guimard/cyrus-postfix-docker)
* [Dockerfile](https://github.com/guimard/cyrus-postfix-docker/blob/master/Dockerfile)
* [Issues database](https://github.com/guimard/cyrus-postfix-docker/issues)

## Copyright and license

Copyright: Xavier (Yadd) Guimard <yadd@debian.org>.

License: [GNU General Public License v2.0](https://github.com/guimard/cyrus-postfix-docker/blob/master/LICENSE)
