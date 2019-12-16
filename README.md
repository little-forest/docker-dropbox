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

### Environment variables

* `USER_ID` : `~/Dropbox` directory's owner uid.
* `GROUP_ID` : `~/Dropbox` directory's owner gid.

### Directories

* `~/Dropbox` : Dropbox synchronized directory.
* `~/.dropbox` : Stores meta files which use dropbox client.

## Quick start a dropbox client as systemd service (recomended)

Assume that the username is `bob`.

```shell-session
$ sudo cp dropbox@.service /etc/systemd/system/
$ sudo systemctl daemon-reload && echo OK
OK
$ sudo systemctl enable dropbox@bob.service
$ sudo systemctl start dropbox@bob.service
```

Unit's instance name should be unix user name.

Systemd controled dropbox docker container name is `dropbox_<instance_name>` such as `dropbox_bob`

### First link to your Dropbox account

On the first start, you have to link your Dropbox account.

After starting dropbox service, please check journal logs.

```shell-session
$ sudo journalctl -fau dropbox@<instance_name>
```

You will see following messages.

```
This computer isn't linked to any Dropbox account...
Please visit https://www.dropbox.com/cli_link_nonce?nonce=XXXXXXXXXXXXXXXXXXXXXXXXXXX to link this device.
```

Visit the URL and link to your account.
When your computer linked successfully, you will see following message.

```
This computer is now linked to Dropbox. Welcome XXXXXX
```

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

