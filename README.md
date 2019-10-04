A squid docker image based on [debians slim releases](https://hub.docker.com/_/debian) with ssl support.  
So you should be able to listen on http and https ports.

### Branches
| Tag          | Branch          | Debian Version  | Squid Version    |
| ------------ | --------------- | --------------- | ---------------- |
| latest       | master          | Sid             | >= 4.8           |
| sid          | master          | Sid             | >= 4.8           |
| stretch      | stretch         | Stretch         | 3.5              |
| buster       | buster          | Buster          | 4.6              |
| bullseye     | bullseye        | Bullseye        | 4.6              |

### HowTo Build
```
docker build \
  -t squid . \
  -f Dockerfile
```

### HowTo Create
```
docker create \
  --name squid \
  -e TZ=Europe/London \
  -e PROXY_UID=13 \
  -e PROXY_GID=13 \
  -v SomePath:/etc/squid \
  -v SomePath:/var/log/squid \
  -v SomePath:/var/spool/squid \
  -p 3128:3128 \
  -p 3129:3129 \
  distahl/squid
```

If you have build the image yourself, switch the last line from `distahl/squid` to `squid`.

### Environment
| Variable      | Default       | Description                                |
| ------------- |:-------------:| ------------------------------------------ |
| TS            | Europe/London | The timezone to use.                       |
| PROXY_UID     | 13            | The user id to use for the squid process.  |
| PROXY_GID     | 13            | The group id to use for the squid process. |

### Volumes
| Volume        | Description                                |
| ------------- |------------------------------------------|
| /etc/squid            | The configuration directory. If no `squid.conf` file is found inside this directory, then the default files will be copied into this directory on docker start.|
| /var/log/squid     | The directory where you can find logfiles.  |
| /var/spool/squid     | By default, this is used for core dumps and cache |

### Ports
| Port     | Description   |
| ---------| ------------- |
| 3128     | HTTP Port     |
| 3129     | HTTPS Port    |

### Additional Info
On first start, if there is no `ssl` directory and `squid.conf` file found inside `/etc/squid`, this image will create the `ssl` directory and adds a selfsigned certificate. Among the certificate you will find a `.pfx`file, which can be imported by Windows to make it trusted. The pfx behaviour is working for Chrome based Browsers, but not for Firefox. In Firefox, just add an exception using the settings.  

If you want to customize the selfsigned cert to match your domain/host, then add a file called `ssl-selfsigned.conf` to `/etc/squid`. This way the openssl command will use your config to create certificates on startup. But this will only happen if there is no `/etc/squid/ssl` directory and also no `/etc/squid/squid.conf` file.

Of course you can also add your own (official) certificates into `ssl` directory and point to them using the config files, which should be best pratice.
