#!/bin/bash

# Inspired by https://github.com/Homegear/Homegear-Docker/blob/master/rpi-stable/start.sh
_term() {
	# "service ... stop" refuses to act on the non-root pidfiles, so signal the
	# daemons directly and give Homegear time to save its peers.
	pkill -TERM -x homegear-influx
	pkill -TERM -x homegear-manage
	pkill -TERM -o -x homegear
	for i in $(seq 50); do
		pgrep -x homegear >/dev/null || break
		sleep 0.5
	done
	exit 0
}

trap _term SIGTERM

USER=homegear

USER_ID=$(id -u $USER)
USER_GID=$(id -g $USER)

USER_ID=${HOST_USER_ID:=$USER_ID}
USER_GID=${HOST_USER_GID:=$USER_GID}

sed -i -e "s/^${USER}:\([^:]*\):[0-9]*:[0-9]*/${USER}:\1:${USER_ID}:${USER_GID}/"  /etc/passwd
sed -i -e "s/^${USER}:\([^:]*\):[0-9]*/${USER}:\1:${USER_GID}/" /etc/group

mkdir -p /config/homegear /share/homegear/lib /share/homegear/log
chown $USER:$USER /config/homegear /share/homegear/lib /share/homegear/log
rm -Rf /etc/homegear /var/lib/homegear /var/log/homegear
ln -nfs /config/homegear     /etc/homegear
ln -nfs /share/homegear/lib /var/lib/homegear
ln -nfs /share/homegear/log /var/log/homegear

if ! [ "$(ls -A /etc/homegear)" ]; then
	cp -R /etc/homegear.config/* /etc/homegear/
fi
# Add config files introduced by newer packages (e.g. php.ini, without which
# PHP deprecation notices end up in the admin UI); never overwrite existing ones
for f in /etc/homegear.config/*; do
	[ -f "$f" ] && cp --update=none "$f" /etc/homegear/
done

if ! [ "$(ls -A /var/lib/homegear)" ]; then
	cp -a /var/lib/homegear.data/* /var/lib/homegear/
else
	mkdir -p /var/lib/homegear/modules /var/lib/homegear/flows/nodes
	rm -Rf /var/lib/homegear/modules/*
	rm -Rf /var/lib/homegear/flows/nodes/*
	cp -a /var/lib/homegear.data/modules/* /var/lib/homegear/modules/
	[ -d /var/lib/homegear.data/flows/nodes ] && cp -a /var/lib/homegear.data/flows/nodes/. /var/lib/homegear/flows/nodes/
	# The admin UI is package content only; an old copy breaks against newer modules
	rm -Rf /var/lib/homegear/admin-ui
	cp -a /var/lib/homegear.data/admin-ui /var/lib/homegear/admin-ui
	# Add directories newer packages ship (ui, web-ssh, ...). Only whole missing
	# directories: the homegear_updated flag file makes homegear-management
	# restart Homegear mid-startup.
	for d in /var/lib/homegear.data/*/; do
		[ -e "/var/lib/homegear/$(basename "$d")" ] || cp -a "$d" /var/lib/homegear/
	done
fi

if ! [ -f /var/log/homegear/homegear.log ]; then
	touch /var/log/homegear/homegear.log
fi

if ! [ -f /etc/homegear/nodeBlueCredentialKey.txt ]; then
	touch /etc/homegear/nodeBlueCredentialKey.txt
	tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' </dev/urandom | head -c 128 >> /etc/homegear/nodeBlueCredentialKey.txt
fi

if ! [ -f /etc/homegear/dh1024.pem ]; then
	openssl genrsa -out /etc/homegear/homegear.key 2048
	openssl req -batch -new -key /etc/homegear/homegear.key -out /etc/homegear/homegear.csr
	openssl x509 -req -in /etc/homegear/homegear.csr -signkey /etc/homegear/homegear.key -out /etc/homegear/homegear.crt
	rm /etc/homegear/homegear.csr
	chown homegear:homegear /etc/homegear/homegear.key
	chmod 400 /etc/homegear/homegear.key
	openssl dhparam -check -text -5 -out /etc/homegear/dh1024.pem 1024
	chown homegear:homegear /etc/homegear/dh1024.pem
	chmod 400 /etc/homegear/dh1024.pem
fi

chown -R root:root /etc/homegear
find /etc/homegear/ -type d -exec chmod 755 {} \;
chown -R homegear:homegear /var/log/homegear/ 
chown -R homegear:homegear /var/lib/homegear/
find /var/log/homegear/ -type d -exec chmod 750 {} \;
find /var/log/homegear/ -type f -exec chmod 640 {} \;
find /var/lib/homegear/ -type d -exec chmod 750 {} \;
find /var/lib/homegear/ -type f -exec chmod 640 {} \;

ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

echo "HOMEGEARUSER=root" > /etc/default/homegear
echo "HOMEGEARGROUP=root" >> /etc/default/homegear

# Leftovers from a previous run of this container make the init scripts
# believe the daemons are still running
rm -f /var/run/homegear/*.pid /var/run/homegear/*.sock

service homegear start
service homegear-management start
service homegear-influxdb start

# No cron in the container: rotate logs hourly so they don't grow unbounded
(while true; do logrotate -s /var/lib/homegear/logrotate.status /etc/logrotate.d/homegear; sleep 3600; done) &

tail -F /var/log/homegear/homegear.log &
child=$!
wait "$child"
