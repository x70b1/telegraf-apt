# telegraf-apt

[![Actions](https://github.com/x70b1/telegraf-apt/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/x70b1/telegraf-apt/actions)
[![Contributors](https://img.shields.io/github/contributors/x70b1/telegraf-apt.svg)](https://github.com/x70b1/telegraf-apt/graphs/contributors)
[![License](https://img.shields.io/github/license/x70b1/telegraf-apt.svg)](https://github.com/x70b1/telegraf-apt/blob/master/LICENSE)

A [Telegraf](https://github.com/influxdata/telegraf) plugin to check Debian, Ubuntu and other apt-based systems for package updates.

This plugin runs continuously and prints an output in the interval requested by Telegraf.
In addition, the output can be triggered externally, e.g. during `apt update` to get the latest status in almost real time.
For Debian, the Debian wiki is queried to check the [LTS status](https://wiki.debian.org/LTS). For Ubuntu, the meta-release changelog is queried to check the [support status](https://changelogs.ubuntu.com/meta-release).
You can make use of [needrestart](https://github.com/liske/needrestart) to check the system for outdated libraries.


## Configuration

Install `curl`. Also `needrestart` if you like to use it.

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

If Telegraf is able to run `needrestart` with sudo privileges, the corresponding metrics will be collected:

```
telegraf    ALL = NOPASSWD: /usr/sbin/needrestart -b
```


## Output

```sh
# sh /opt/telegraf/telegraf-apt.sh
apt os_id="Debian"
apt os_release="11.2"
apt os_codename="Bullseye"
apt os_support=0
apt updates_regular=0
apt updates_security=1
apt updates_packages=""
apt updates_severity=2
apt needrestart_services=6
apt needrestart_severity=1
```

## How to read

**os_id**

Returns the value of `ID` from `/etc/os-release`.


**os_release**

Returns the value of `VERSION_ID` from `/etc/os-release`.


**os_codename**

Returns the value of `VERSION_CODENAME` from `/etc/os-release`.


**os_support**

Returns the current support status of your system. Supported on Debian and Ubuntu only.

For Debian:

```
0   =  full support with official security fixes
1   =  LTS with limitied security support
2   =  outdated
```

For Ubuntu:

```
0   =  supported
2   =  unsupported
```

_For Ubuntu this will not consider Ubuntu Pro licensing/extended support._


**updates_regular**

Returns the number of outstanding regular updates.


**updates_security**

Returns the number of outstanding security updates.


**updates_packages**

Returns a list of packages with outstanding updates.


**updates_severity**

Returns an integer indicator as summary for Debian and Ubuntu.

For Debian:

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

For Ubuntu:

```
0   =  full Ubuntu support, no updates

1   =  full Ubuntu support, one or more regular updates
2   =  full Ubuntu support, one or more security updates
3   =  full Ubuntu support, one or more regular updates and one or more security updates

20  =  unsupported, no updates
21  =  unsupported, one or more regular updates
22  =  unsupported, one or more security updates
23  =  unsupported, one or more regular updates and one or more security updates
```

**needrestart_services**

Returns the number of services which need to be restarted after library upgrades.


**needrestart_severity**

Returns an integer indicator as summary.

```
0   =  latest available kernel is running and no services with outdated libraries
1   =  latest available kernel is running and one or more services with outdated libraries
2   =  latest available kernel is not running and no services with outdated libraries
3   =  latest available kernel is not running and one or more services with outdated libraries
```
