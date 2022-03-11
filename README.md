# telegraf-apt

[![Codecheck](https://github.com/x70b1/telegraf-apt/workflows/Codecheck/badge.svg?branch=master)](https://github.com/x70b1/telegraf-apt/actions)
[![GitHub contributors](https://img.shields.io/github/contributors/x70b1/telegraf-apt.svg)](https://github.com/x70b1/telegraf-apt/graphs/contributors)
[![license](https://img.shields.io/github/license/x70b1/telegraf-apt.svg)](https://github.com/x70b1/telegraf-apt/blob/master/LICENSE)

A [Telegraf](https://github.com/influxdata/telegraf) plugin to check Debian for package updates.

This plugin runs continuously and prints an output in the interval requested by Telegraf.
In addition, the output can be triggered externally, e.g. during `apt update` to get the latest status in almost real time.
The Debian wiki is queried to check the [LTS status](https://wiki.debian.org/LTS).


## Configuration

Install `curl`.

To make this plugin useful you need a way to keep your package sources up to date.
You can use `unattended-upgrades` to run `apt update` on a regular basis.
To trigger the plugin to collect new stats after an `apt update`, create a `Post-Invoke` configuration.
You can copy [99telegraf](99telegraf) to `/etc/apt/apt.conf.d/99telegraf` or use it as example.

Telegraf can be configured like this:

```ini
[[inputs.execd]]
  command = ["/bin/sh", "/opt/telegraf/telegraf-apt.sh"]
  data_format = "influx"

  interval = "24h"
  signal = "SIGUSR1"
```


## Output

```sh
# sh /opt/telegraf/telegraf-apt.sh
apt debian_release="11.2"
apt debian_codename="Bullseye"
apt debian_support=0
apt updates_regular=0
apt updates_security=1
apt updates_severity=2
```


## How to read

**debian_release**

Returns the release from `/etc/debian_version`.


**debian_codename**

Returns a codename like `Bullseye`, `Buster` ...


**debian_support**

Returns the current support status of your system.

```
0   =  full support with official security fixes
1   =  LTS with limitied security support
2   =  outdated
```


**updates_regular**

Returns the number of outstanding regular updates.


**updates_security**

Returns the number of outstanding security updates.


**updates_severity**

Returns an integer indicator as summary.

```
0   =  full Debian support, no updates

1   =  full Debian support, one or more regular updates
2   =  full Debian support, one or more security updates
3   =  full Debian support, one or more regular updates and one or more security updates

10  =  LTS, no updates
11  =  LTS, one or more regular updates
12  =  LTS, one or more security updates
13  =  LTS, one or more regular updates and one or more security updates

20  =  outdated, no updates
21  =  outdated, one or more regular updates
22  =  outdated, one or more security updates
23  =  outdated, one or more regular updates and one or more security updates
```
