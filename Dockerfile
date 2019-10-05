FROM debian:stretch-slim

RUN ln -sf /bin/bash /bin/sh

#RUN echo 'deb http://deb.debian.org/debian stretch-backports main' > /etc/apt/sources.list.d/backports.list
#RUN echo 'deb-src http://deb.debian.org/debian stretch-backports main' >> /etc/apt/sources.list.d/deb-sources.list
RUN echo 'deb-src http://deb.debian.org/debian stretch main' >> /etc/apt/sources.list.d/deb-sources.list

RUN DEBIAN_FRONTEND=noninteractive && \
	apt-get update && \
	apt-get install -y locales && \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
	apt-get clean && apt-get autoclean && \
	rm -rf /var/lib/apt/lists/*
	
RUN DEBIAN_FRONTEND=noninteractive && \
	apt-get update && \
	apt-get dist-upgrade -y && \
	apt-get clean && apt-get autoclean && \
	rm -rf /var/lib/apt/lists/*

ENV LANG en_US.utf8
ENV PATH="${PATH}:/xbin"
ENV TZ Europe/London
ENV PROXY_UID 13
ENV PROXY_GID 13

COPY squid_ssl.patch /tmp/squid_ssl.patch

RUN DEBIAN_FRONTEND=noninteractive && \
	apt-get update && \
	apt-get install -y tzdata busybox openssl libssl1.0-dev devscripts && \
	mkdir /xbin && /bin/busybox --install -s /xbin && \
	echo "---------------------------------------------------------------------------------"&& \
	test ! -d /usr/src/squid && mkdir -p -m0777 /usr/src/squid || true && \
	cd /usr/src/squid && \
	mk-build-deps squid3 && \
	dpkg -i squid3-build* || true && \
	apt-get install -y -f && \
	rm -f squid3-build-deps* && \
	echo "---------------------------------------------------------------------------------"&& \
	apt-get source -y squid3 && \
	mv /tmp/squid_ssl.patch . && \
	cd squid3-* && \
	patch -p1 debian/rules < ../squid_ssl.patch && \
	debuild -us -uc && \
	rm -f ../*-dbg*.deb && \
	rm -f ../*-cgi*.deb && \
	dpkg -i ../*.deb || true && \
	apt-get install -y -f && \
	echo "---------------------------------------------------------------------------------"&& \
	apt-get remove --purge --auto-remove -y squid3-build-deps devscripts && \
	apt-get clean && apt-get autoclean && \
	rm -rf /var/lib/apt/lists/* && \
	cd / && rm -rf /usr/src/squid
	
RUN mv /etc/squid /etc/squid.dist && \
	mkdir /etc/squid.dist/conf.d && \
	sed -i 's/^#http_access allow localnet/http_access allow localnet/g' /etc/squid.dist/squid.conf && \
	sed -i 's/^#acl localnet/acl localnet/g' /etc/squid.dist/squid.conf && \
	echo -e "\n\n include /etc/squid.dist/conf.d/*" >> /etc/squid.dist/squid.conf && \
	mkdir /etc/squid

COPY ssl-selfsigned.conf /etc/squid.dist/ssl-selfsigned.conf
COPY ssl.conf /etc/squid.dist/conf.d/ssl.conf	
COPY start-squid.sh /bin/start-squid.sh

VOLUME /etc/squid
VOLUME /var/log/squid
VOLUME /var/spool/squid

EXPOSE 3128/tcp	
EXPOSE 3129/tcp
	
ENTRYPOINT ["/bin/start-squid.sh"]