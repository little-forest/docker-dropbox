# Dropbox client in Docker with systemd unit

Dropbox client docker image that has the following futures.

* Supports any UID/GID.
* Can use cli client(dropbox.py) from host.
* Provides systemd unit file, so you can operate dropbox easily on CentOS7.

## Quick start

```shell-session
$ mkdir ~/Dropbox ~/.dropbox
# docker run --rm --name=dropbox \
    -e USER_ID=1000 \
    -e GROUP_ID=1000 \
    -v ~/Dropbox:/home/dbox/Dropbox \
    -v ~/.dropbox:/home/dbox/.dropbox \
    -v /etc/localtime:/etc/localtime:ro \
    littlef/dropbox
```

## Quick start a dropbox client as systemd service

Assume that the username is bob.

```shell-session
$ sudo cp dropbox@.service /etc/systemd/system/
$ sudo systemctl daemon-reload && echo OK
OK
$ sudo systemctl start dropbox@bob.service
```

Unit's instance name should be unix user name.

Systemd controled dropbox docker container name is "dropbox_<instance name>" such as "dropbox_bob"

### How to show dropbox client status

You can use dropbox cli command (dropbox.py) as follows.

```shell-session
$ docker exec -it <container name> /dropbox <command>
```

For example you can show dropbox client status as follows.

```shell-session
$ docker exec -it <container name> /dropbox status
```

For more details, please use help command.

```shell-session
$ docker exec -it <container name> /dropbox help
```

