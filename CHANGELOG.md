# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/).

## Unreleased

## [1.2.12] - 2022-04-06
### Changed
- Aligned branch versions

## [1.2.11] - 2022-04-06
### Changed
- slurm-gen-qos-conf: Fixed syntax errors to make the script usable again
- job_submit.lua:
  - Removed unneeded spaces in function definitions
  - Added a prefix to all log messages and reformatted them to include more information

## [1.2.10] - 2022-02-08
### Changed
- job_submit.lua:
  - Added '.' and ':' to the list of valid characters one can use for a job name
  - Misc error formating fixes

## [1.2.9] - 2022-01-25
### Changed
- slurm-gen-qos-conf:
    - only writes QoSes matching our format (separated by '_' with the first item being a partition)
- job_submit.lua:
  - Make regex error message clearer by showing the list of allowed characters instead of the regex
  - Exclude non matching QoS' names from partition validation: a QoS not matching the format specified above won't be checked for valid partition

## [1.2.8] - 2022-01-13
### Changed
- slurm-gen-qos-conf: some cleaning and only only keep QoS which matches partitions
- job_submit.lua:
  - lots of cleaning
  - added a logging function so we can return error messages to the user
  - job names have to match a regex
  - job names have to under a fixed length
  - now returns an error if we don't find a matching QoS when it's not provided
  - now returns an error if we don't find a default partition if none was provided
  - ensure job's time limit is compatible with the QoS' time limit
  - fixed a bug in to_minute where d-h would be converted to d-h, ensure we actually match digits and returns 0 if we found nothing
  - slurm only expects a limited set of return results so some of them had to be converted to slurm.ERROR (for example: ESLURM_INVALID_WCKEY and ESLURM_INVALID_QOS)
  - when the user provided both QoS and partition, make sure they match
  - because we rewrote a portion of the build_qos, now we can iterate the list of QoSes matching a given partition to find one matching the time limit, number of nodes and accounts if needed
  - if a QoS wasn't provided and we either used the default partition or the provided one, make sure we have matching QoSes, if not, returns an error
- slurm-sync-accounts: some cleaning and added logic so the script doesn't what's necessary when a user should have multiple associations or when a user should have its current association(s) replaced

## [1.2.7] - 2021-04-28
### Changed
- epilog: log meaningful error in cases epilog exits prematurely

## [1.2.6] - 2021-02-26
### Changed
- taskprolog: imporive renewer for canonical cache

## [1.2.5] - 2021-02-25
### Added
- taskepilog: Add logging at the end of tasks
### Changed
- taskprolog: imporive renewer for canonical cache

## [1.2.4] - 2021-02-18
### Changed
- taskprolog: lustre add renewer for canonical ccache

## [1.2.3] - 2021-01-08
### Changed
- Use /etc/slurm on all Linux distributions

## [1.2.2] - 2020-12-24
### Unknown
- epilog: detect if cgroup uses slurm or slurm_HOSTNAME

## [1.2.1] - 2020-12-16
### Unknown
- wckeys: EL8 compatibility

## [1.2.0] - 2020-12-04
### Unknown
- taskprolog for lustre kerberos

## [1.1.1] - 2020-12-04
### Unknown
- Python3 port and EL8 compatibilty

## [1.1.0] - 2020-11-02
### Unknown
- Python3 port and EL8 compatibility

## [1.0.4] - 2020-10-01
### Removed
- genscripts: don't remove other jobs private-tmpdir

## [1.0.3] - 2019-11-26
### Unknown
- slurmdbd-backup: Use single-transaction by default

## [1.0.2] - 2019-10-14
### Fixed
- correct a bug on slurm-wckeys-setup when tmpfs is not umount when we have a exit code error

## [1.0.1] - 2019-09-16
### Unknown
- genscripts: rework cgroup cleaning in epilog

## [1.0.0] - 2019-08-20
### Removed
- admin-utils: remove NUL char from node-list-procs

### Added
- admin-utils: Add slurm-check-cgroups-nojob
- add cgroups script to slurm-admin-utils
- admin-utils nodes-only to slurm-check-procs-nojob

## [0.11.3] - 2019-07-24
### Fixed
- Epilog.d: Fix tmp cleaning bug and cgroups non cleaned problem

## [0.11.2] - 2019-06-19
### Added
- admin-utils: add new admin script to manage kill task failled in slurmd nodes

## [0.11.1] - 2019-06-03
### Unknown
- admin-utils: do not json decode failing nodes

## [0.11.0] - 2019-05-15
### Added
- introduce new binary package slurm-admin-utils
- admin-utils: introduce slurm-check-procs-nojob

## [0.10.0] - 2019-05-10
### Changed
- genscripts: replace squeue with cpuset check
- genscripts: log pkill count in clean epilog

## [0.9.0] - 2019-04-18
### Added
- sync-accounts: allow multiple groups per accounts

## [0.8.4] - 2018-11-13
### Fixed
- correct an other bug introduce by 0e2b780d6ac1

## [0.8.3] - 2018-11-13
### Fixed
- correct a bug introduce by 0e2b780d6ac1

## [0.8.2] - 2018-11-09
### Added
- new release to be in sync with scibian repo

## [0.8.1] - 2018-11-09
### Fixed
- job_submit.lua: correct a problem in build_qos_list by setting qos_maxtime to infinite when this variable is not define

## [0.8.0] - 2018-10-15
### Removed
- job_submit.lua: remove getent to get username

### Changed
- job_submit.lua: replace grep with Lua stdlib io
- job_submit.lua: replace cat + remove sacctmgr
- job_submit.lua: handle unexiting account

## [0.7.16] - 2018-02-15
### Changed
- Ensure the files are in ASCII unix mode before operating on it

## [0.7.15] - 2018-01-24
### Changed
- Send cron output to /dev/null

## [0.7.14] - 2018-01-16
### Changed
- Make slurm-llnl-setup-wckeys Breaks/Replaces old slurm-llnl-job-submit-plugin to ensure smooth upgrades.

## [0.7.13] - 2018-01-09
### Added
- Add dependancy between slurm-llnl-job-submit-plugin and slurm-llnl-setup-wckeys

## [0.7.12] - 2018-01-09
### Removed
- Remove bsdutils dependancy as it's an essential package

### Fixed
- Bugfix crontab for slurm-llnl-setup-wckeys

## [0.7.11] - 2018-01-05
### Added
- Move slurm-wckeys-setup in new binary package
- Add a cronjob for slurm-wckeys-setup

### Changed
- Use curl instead of wget Simpler logic in script and uniformisation for files locations in config
- Log messages and errors in syslog

## [0.7.10] - 2017-12-05
### Changed
- Bugfix packaging : rename script slurm-wckeys-setup in install file

## [0.7.9] - 2017-12-05
### Changed
- slurm-wckeys-setup: Update header
- slurm-wckeys-setup: Rename slurm_wckeys_setup.sh in slurm-wckeys-setup

### Fixed
- slurm-wckeys-setup: Bugfix : file not found is ${SLURMDB_FILE} and not ${CODES_FILE}

### Added
- slurm-wckeys-setup: Add possiblity to download pareo and codes files by http

## [0.7.8] - 2017-08-25
### Changed
- mysql-setup: manage password changes

### Added
- mysql-setup: do not create slurm DB
- mysql-setup: do not create users with grant opt

## [0.7.7] - 2017-08-24
### Added
- mysql-setup: add feature to restrict slurmro hosts

## [0.7.6] - 2017-08-03
### Unknown
- job_submit: split optimization

## [0.7.5] - 2017-07-13
### Fixed
- sync-accounts: fix user account description string

## [0.7.4] - 2017-07-04
### Unknown
- sync-accounts: handle multiple src posix groups

## [0.7.3] - 2017-06-19
### Changed
- pwmgt: disable SSH strict host key checking

### Fixed
- pwmgt: fix debug formatting string

### Unknown
- pwmgt: daemonize stop wrapper cmd
- pkg: pwmgt stop wrapper now depends on daemon lib

## [0.7.2] - 2017-02-23
### Fixed
- packaging: fix distribution

## [0.7.1] - 2017-02-23
### Unknown
- job_submit: os.execute compatible with lua 5.1 and 5.2

## [0.7.0] - 2017-02-03
### Added
- slurmdbd-backup: Add SlurmDBD backup script
- slurmdbd-backup: Add packaging

## [0.6.0] - 2016-12-21
### Unknown
- Introduce pwmgt utility

## [0.5.3] - 2016-11-18
### Fixed
- slurm_wckeys_setup.sh: Fix bug wckeys (applications and projects order)

## [0.5.2] - 2016-11-17
### Unknown
- slurm_wckeys_setup.sh: Manage multiple projects and applications CSV

## [0.5.1] - 2016-11-16
### Removed
- job_submit.lua: remove useless code branch

### Unknown
- gen qos.conf script now extract accounts
- job_submit.lua: handle empty maxcpus in CSV
- job_submit.lua: manage multiple qos same settings
- job_submit.lua: check allowed accounts from CSV

## [0.5.0] - 2016-11-14
### Unknown
- sync-accounts: support multiple groups

## [0.4.7] - 2016-05-26
### Added
- sync-account: add opts creation cmd params

## [0.4.6] - 2016-04-28
### Fixed
- Fix bugs in slurm-gen-qos-conf

## [0.4.5] - 2015-10-28
### Fixed
- Fix ugly bugs in sync-account script

## [0.4.4] - 2015-10-23
### Removed
- job-submit: Remove examples CSV and user exception files since
- sync-accounts: Remove user before account w/ user_account policy
- remove examples irrelevant in production.

## [0.4.3] - 2015-10-22
### Removed
- Remove all trailing whitespaces in slurm_wckeys_setup.sh

### Changed
- Do not convert in uppercase in final wckeys file

### Fixed
- Fix mysql command params in slurm_wckeys_setup.sh

### Unknown
- Do not convert dash into underscore anymore

## [0.4.2] - 2015-10-19
### Fixed
- Backport slurm-gen-qos-conf to python 2.6 and fix empty QOS case

### Unknown
- Backport slurm-sync-accounts to python 2.6

## [0.4.1] - 2015-10-09
### Added
- sync-accounts: add missing dep on slurm-client

## [0.4.0] - 2015-10-08
### Added
- Add new sync-accounts package

## [0.3.9] - 2015-09-30
### Added
- Add job fields in slurm log to help debug in Lua submit plugin

## [0.3.8] - 2015-09-11
### Changed
- All changes are relative to the job_submit.lua script.
- For exclusive jobs, set job_desc.min_nodes to 1 by default.
- Cosmetic change: update file header.
- Replace tabs with spaces.

### Added
- Add ability to use a configuration file (/etc/slurm-llnl/job_submit.conf)
  in which administrators can specify the following parameters:
  - QOS_CONF
  - QOS_SEP
  - QOS_NAME_SEP
  - NULL
  - CORES_PER_NODE
  - ESLURM_INVALID_WCKEY
  - WCKEY_CONF_FILE
  - WCKEY_USER_EXCEPTION_FILE
  The aformentioned keys have sensible values in the .lua script. Special care
  must be taken with the CORES_PER_NODE parameter which must be configured for
  each cluster depending on the configuration of the compute nodes.
  The syntax of /etc/slurm-llnl/job_submit.conf is simple (In fact, it is a lua
  script): Lines of the shape "<key> = <value>".
- Emit a message when the user specifies a QOS.

## [0.3.7] - 2015-07-17
### Changed
- Fix clean epilog script
- Do not fail when JOB_ID is not numeric
- Do not consider UIDs less than 1000

## [0.3.6] - 2015-03-11
### Fixed
- Fix job submit LUA script

## [0.3.5] - 2015-03-10
### Fixed
- Somes fixes in shell script slurm_wckeys_setup.sh

## [0.3.4] - 2015-03-03
### Changed
- Do not recommend slurm-llnl anymore.

## [0.3.3] - 2015-02-18
### Added
- Add QOS exceptions in slurm-gen-qos-conf

## [0.3.2] - 2015-01-07
### Added
- Add function to force the use of wckey.

## [0.3.1] - 2015-01-02
### Changed
- Large update of job_submit.lua for slurm 14.11.x
- Package job submit plugin now depends on slurm >= 14.11

## [0.3.0] - 2014-10-06
### Changed
- Updated dep from slurm-llnl-basic-plugins to
- slurm-wlm-basic-plugins since pkg name has changed.

### Added
- Add a python script to setup mysql for SlurmDBD
- in a new package slurm-llnl-setup-mysql.
- New script slurm-gen-qos-conf to generate qos.conf for
- Add missing dependency to members and infiniband-diags on
- slurm-llnl-node-health-plugin pkg.

### Unknown
- Moved content of job-submit package in dedicated subdir  Lua job submit plugin.
- Check return code of ibstat in check_node_health script
- Restrict IB rate check to port 1 only

## [0.2.4] - 2014-03-26
### Changed
- Update job_submit.lua

### Fixed
- Fix detection of fs usage in check_node_health.sh

## [0.2.3] - 2013-12-17
### Fixed
- Yet anoter typo fix in generic-script.sh.

## [0.2.2] - 2013-11-19
### Fixed
- Fix generic-script.sh to check for regular files as well as symlinks.

## [0.2.1] - 2013-11-19
### Fixed
- Ldap check bug fix

## [0.2] - 2013-11-18
### Changed
- Update check_node_health.sh script

## [0.1] - 2013-10-16
### Added
- Initial Release
