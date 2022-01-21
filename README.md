# telegraf-apt

[![Codecheck](https://github.com/x70b1/telegraf-apt/workflows/Codecheck/badge.svg?branch=master)](https://github.com/x70b1/telegraf-apt/actions)
[![GitHub contributors](https://img.shields.io/github/contributors/x70b1/telegraf-apt.svg)](https://github.com/x70b1/telegraf-apt/graphs/contributors)
[![license](https://img.shields.io/github/license/x70b1/telegraf-apt.svg)](https://github.com/x70b1/telegraf-apt/blob/master/LICENSE)


A telegraf plugin to check Debian for package updates.

The debian website is queried to check the LTS status.
For this `curl` is required as a dependency.

To make this script useful you need a way to keep your package sources up to date.
You can use `unattended-upgrades` to run `apt update` on a regular basis.


## Configuration

```
[[inputs.exec]]
  command = "sh /opt/telegraf/telegraf-apt.sh"
  data_format = "influx"

  interval = "1h"
```


## Output

```
sh /opt/telegraf/telegraf-apt.sh
apt debian_release="11.2"
apt debian_codename="bullseye"
apt debian_support=0
apt updates_regular=0
apt updates_security=1
apt updates_severity=2
```


## How to read

##### debian_release

Returns the release from `/etc/debian_version`.


##### debian_codename

Returns a codename like `bullseye`, `buster` ...


##### debian_support

Returns the current support status of your system.

```
0   =  full support with official security fixes
1   =  LTS with limitied security support
2   =  outdated
```


##### updates_regular

Returns the number of outstanding regular updates.


##### updates_security

Returns the number of outstanding security updates.


##### updates_severity

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
