#!/bin/bash

NAME=squid
DESC="Squid HTTP Proxy"
DAEMON=/usr/sbin/squid
CONFDIR=/etc/squid
CONFIG=$CONFDIR/squid.conf

if [[ ! -f $CONFIG ]]; then
	echo "###########################################################"
	echo "No userdefined $CONFIG found. Will now copy the dist files."
	echo "###########################################################"
	find /etc/squid.dist/ -mindepth 1 -maxdepth 1 | \
		while read FILE; do \
			[[ ! -d $CONFDIR/$(basename $FILE) && ! -f $CONFDIR/$(basename $FILE) ]] && \
				cp -avr $FILE $CONFDIR/
		done
	echo "###########################################################"
	echo
fi

if [[ ! -d $CONFDIR/ssl ]] && [[ -f /etc/squid.dist/ssl-selfsigned.conf || -f /etc/squid/ssl-selfsigned.conf ]]; then
	echo "#########################################################################"
	echo "No $CONFDIR/ssl directory found. Will now create selfsigned certificates."
	echo "#########################################################################"
	SSLCONF=/etc/squid.dist/ssl-selfsigned.conf
	[[ -f /etc/squid/ssl-selfsigned.conf ]] && SSLCONF=/etc/squid/ssl-selfsigned.conf
	mkdir $CONFDIR/ssl && \
	openssl req -new \
		-newkey rsa:4096 -sha256 -nodes -keyout $CONFDIR/ssl/selfsigned.key \
		-days 99365 \
		-x509 -out $CONFDIR/ssl/selfsigned.crt \
		-config $SSLCONF && \
	cat $CONFDIR/ssl/selfsigned.{key,crt} > $CONFDIR/ssl/selfsigned.chain && \
	openssl pkcs12 -export -passout pass: \
		-in $CONFDIR/ssl/selfsigned.chain \
		-out $CONFDIR/ssl/selfsigned.pfx
	echo "#########################################################################"
	echo
fi

if [[ -n $PROXY_UID && $(id -u proxy 2>/dev/null) != $PROXY_UID ]]; then
	echo "##################################################"
	echo "Configured user id changed. Setting permissions..."
	echo "##################################################"
	find / -user proxy -exec chown -vhR $PROXY_UID {} \; 2>/dev/null
	usermod -u $PROXY_UID proxy 2>/dev/null
	echo "##################################################"
	echo
fi
	
if [[ -n $PROXY_GID && $(id -g proxy 2>/dev/null) != $PROXY_UID ]]; then
	echo "###################################################"
	echo "Configured group id changed. Setting permissions..."
	echo "###################################################"
	find / -group proxy -exec chgrp -vhR $PROXY_GID {} \; 2>/dev/null
	groupmod -g $PROXY_GID proxy 2>/dev/null
	echo "###################################################"
	echo
fi

SQUID_ARGS="-N -YC -d1 -f $CONFIG"

[ ! -f /etc/default/squid ] || . /etc/default/squid
. /lib/lsb/init-functions

PATH=/bin:/usr/bin:/sbin:/usr/sbin

if [ ! -x $DAEMON ]; then echo "ERROR $DAEMON is not executable!"; exit 0; fi

ulimit -n 65535

find_cache_dir () {
        w="     " # space tab
        res=`$DAEMON -k parse -f $CONFIG 2>&1 |
                grep "Processing:" |
                sed s/.*Processing:\ // |
                sed -ne '
                        s/^['"$w"']*'$1'['"$w"']\+[^'"$w"']\+['"$w"']\+\([^'"$w"']\+\).*$/\1/p;
                        t end;
                        d;
                        :end q'`
        [ -n "$res" ] || res=$2
        echo "$res"
}

grepconf () {
        w="     " # space tab
        res=`$DAEMON -k parse -f $CONFIG 2>&1 |
                grep "Processing:" |
                sed s/.*Processing:\ // |
                sed -ne '
                        s/^['"$w"']*'$1'['"$w"']\+\([^'"$w"']\+\).*$/\1/p;
                        t end;
                        d;
                        :end q'`
        [ -n "$res" ] || res=$2
        echo "$res"
}

create_run_dir () {
        run_dir=/var/run/squid
        usr=`grepconf cache_effective_user proxy`
        grp=`grepconf cache_effective_group proxy`

        if [ "$(dpkg-statoverride --list $run_dir)" = "" ] &&
           [ ! -e $run_dir ] ; then
                mkdir -p $run_dir
                chown $usr:$grp $run_dir
                [ -x /sbin/restorecon ] && restorecon $run_dir
        fi
}

cache_dir=`find_cache_dir cache_dir`
cache_type=`grepconf cache_dir`
run_dir=/var/run/squid

#
# Create run dir (needed for several workers on SMP)
#
create_run_dir

#
# Create spool dirs if they don't exist.
#
if test -d "$cache_dir" -a ! -d "$cache_dir/00"
then
        log_warning_msg "Creating $DESC cache structure"
        $DAEMON -z -f $CONFIG
        [ -x /sbin/restorecon ] && restorecon -R $cache_dir
fi

umask 027
ulimit -n 65535
cd $run_dir

$DAEMON $SQUID_ARGS