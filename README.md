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

## Using Dropbox clinet with non-ext4 filesystems. 

Dropbox client only supports ext4 filesystem.
(see https://help.dropbox.com/desktop-web/system-requirements)

If your filesystem is not ext4 such as xfs, you can create local ext4 filesystem using loopback filesystem.

Assume that the username is bob.

```shell-session
$ truncate -s 1G /home/bob/.img/dropbox.img
$ mkfs.ext4 /home/bob/.img/dropbox.img
$ mkdir ~/Dropbox
$ sudo mount -o loop -t ext4 /home/bob/.img/dropbox.img ~/Dropbox
$ sudo chown -R bob:bob /home/bob/Dropbox
```

Check result.

```shell-session
$ df -T /home/bob/Dropbox
Filesystem     Type 1K-blocks    Used Available Use% Mounted on
/dev/loop2     ext4  10190100 7964172   1685256  83% /home/bob/Dropbox
```

For systemd mount unit, create `/etc/systemd/system/home-bob-Dropbox.mount` as follows.

```
[Unit]
Description=Mount Dropbox directory
After=network-online.target
Wants=network-online.target

[Mount]
What=/home/bob/.img/dropbox.img
Where=/home/bob/Dropbox
Options=loop
Type=ext4
TimeoutSec=30

[Install]
WantedBy=multi-user.target
```

Mount using mount unit file.

```shell-session
$ sudo systemctl daemon-reload
$ sudo systemctl start home-bob-Dropbox.mount
$ sudo systemctl enable home-bob-Dropbox.mount
```
