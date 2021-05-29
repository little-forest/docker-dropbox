# How to upgrade Dropbox daemon version

You can get the latest version of linux headless application and CLI application from the following URL.

https://www.dropbox.com/install-linux

## Check latest daemon version

Download latest headless linux application.

```
wget -O - "https://www.dropbox.com/download?plat=lnx.x86_64" | tar xzf -
```

Check daemon version.

```
cat .dropbox-dist/VERSION
123.4.4832
```

## Check latest CLI version

Download latest CLI application.

```
curl -L -o dropbox.py https://www.dropbox.com/download?dl=packages/dropbox.py
chmod +x dropbox.py
```

Check version.

```
./dropbox.py version
Dropbox daemon version: 98.4.158
Dropbox command-line interface version: 2020.03.04
```

## Fix script

Change `DAEMON_VERSION` valiable in `entrypoint.sh`.

```
DAEMON_VERSION=123.4.4832
CLI_VERSION=2020.03.04
```

