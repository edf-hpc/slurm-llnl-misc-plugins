# Configuration Logic
%define name slurm-llnl-misc-plugins
%define version 1.2.11
%define debug_package %{nil}

# Main preamble
Summary: Miscelaneous plugins for Slurm open source scheduler
Name: slurm-llnl-misc-plugins
Version: 1.2.11
Release: 1%{?dist}.edf
Source0: %{name}-%{version}.tar.gz
License: GPLv3
Group: Application/System
Prefix: %{_prefix}
Vendor: EDF CCN HPC <dsp-cspito-ccn-hpc@edf.fr>
Url: https://github.com/edf-hpc/%{__name}

%prep
%setup -q

%build

%install
# Common
mkdir -p %{buildroot}/usr/sbin
mkdir -p %{buildroot}/etc/slurm
mkdir -p %{buildroot}/etc/sysconfig

# slurm-llnl-generic-scripts-plugin
install -d %{buildroot}/usr/lib/slurm/generic-scripts
install -m 755 generic-script.sh %{buildroot}/usr/lib/slurm/generic-scripts
for step in Prolog SrunProlog TaskProlog PrologSlurmctld Epilog SrunEpilog TaskEpilog EpilogSlurmctld
do
    install -d %{buildroot}/usr/lib/slurm/generic-scripts/${step}.d
    ln -s /usr/lib/slurm/generic-scripts/generic-script.sh %{buildroot}/usr/lib/slurm/generic-scripts/${step}.sh
done
install -m 755 Epilog.d/00_clean %{buildroot}/usr/lib/slurm/generic-scripts/Epilog.d

# slurm-llnl-generic-scripts-plugin-lgssc
install -m 755 TaskProlog.d/kerberos_lustre.sh %{buildroot}/usr/lib/slurm/generic-scripts/TaskProlog.d
install -m 755 TaskEpilog.d/kerberos_lustre.sh %{buildroot}/usr/lib/slurm/generic-scripts/TaskEpilog.d

# slurm-llnl-job-submit-plugin
mkdir -p %{buildroot}/etc/slurm/wckeysctl
install -m 755 job_submit/job_submit.lua %{buildroot}/usr/lib/slurm
install -m 755 job_submit/slurm-gen-qos-conf %{buildroot}/usr/sbin

#DEPRECATED slurm-llnl-node-health-plugin

#BATCH slurm-llnl-setup-mysql
install -m 755 mysql-setup/slurm-mysql-setup %{buildroot}/usr/sbin
install -m 640 mysql-setup/slurm-mysql.conf %{buildroot}/etc/slurm

#BATCH slurm-llnl-setup-wckeys
install -m 755 wckeys-setup/slurm-wckeys-setup %{buildroot}/usr/sbin
install -m 644 wckeys-setup/wckeysctl %{buildroot}/etc/sysconfig
mkdir -p %{buildroot}/etc/cron.d
echo "50 * * * * root /usr/sbin/slurm-wckeys-setup >/dev/null 2>&1" > %{buildroot}/etc/cron.d/slurm-llnl-setup-wckeys

#BATCH slurm-llnl-sync-accounts
install -m 755 sync-accounts/slurm-sync-accounts %{buildroot}/usr/sbin
install -m 644 sync-accounts/sync-accounts.conf %{buildroot}/etc/slurm
mkdir -p %{buildroot}/etc/cron.d
echo "0 3 * * * root /usr/sbin/slurm-sync-accounts" > %{buildroot}/etc/cron.d/slurm-llnl-sync-accounts

#BATCH slurmdbd-backup
mkdir -p %{buildroot}/var/backups/slurmdbd
mkdir -p %{buildroot}/var/backups/slurmdbd/database
install -m 755 slurmdbd-backup/slurmdbd-backup %{buildroot}/usr/sbin
install -m 644 slurmdbd-backup/slurmdbd-backup.vars %{buildroot}/etc/slurm

#LOWPRIO slurm-pwmgt-nodes

#LOWPRIO slurm-pwmgt-stop-wrapper

#LOWPRIO slurm-admin-utils

#LOWPRIO slurm-unkstep-program

%clean
rm -rf %{buildroot}

%description
Miscelaneous plugins for Slurm open source scheduler

# slurm-llnl-generic-scripts-plugin package
%package -n slurm-llnl-generic-scripts-plugin
Summary: Generic Prolog and Epilog scripts for Slurm
Group: Application/System
%description -n slurm-llnl-generic-scripts-plugin
The job scheduler Slurm can execute so called Prolog and Epilog scripts
at different stages of each job. For each stage, one script has to appear
in Slurm\'s configuration file.
This package provides a generic script that can be linked to in order to
behave as a (Pro|Epi)log script using an associated (Pro|Epi)log.d directory
next to it. The latter should contain executable scripts that will be run
for the specified stage.

%package -n slurm-llnl-generic-scripts-plugin-lgssc
Summary: Slurm Task Prolog to initialize lustre kerberos
Group: Application/System
Requires: slurm-llnl-generic-scripts-plugin
%description -n slurm-llnl-generic-scripts-plugin-lgssc
This package provides a task prolog script to setup lustre kerberos
keys.

# slurm-llnl-job-submit-plugin
%package -n slurm-llnl-job-submit-plugin
Summary: Lua plugin for routing jobs in approriate defined QOSes
Group: Application/System
Requires: lua, slurm
%description -n slurm-llnl-job-submit-plugin
This package provides a lua script for routing jobs in appropriate QOSes
depending on the compute resources asked by the job.


#DEPRECATED slurm-llnl-node-health-plugin


#BATCH slurm-llnl-setup-mysql
%package -n slurm-llnl-setup-mysql
Summary: MySQL setup script for SlurmDBD
Group: Application/System
Requires: python3-mysqlclient
%description -n slurm-llnl-setup-mysql
This package provides a Python script which setup MySQL server, creates the
databases and gives all needed grants to the slurm user of SlurmDBD. It is
designed to be idempotent by doing only what is needed. This makes it
eventually usable within Puppet manifests for instance.


#BATCH slurm-llnl-setup-wckeys
%package -n slurm-llnl-setup-wckeys
Summary: slurm-llnl-setup-wckeys
Group: Application/System
Requires: curl, dos2unix
%description -n slurm-llnl-setup-wckeys
This package provides a Shell script which add wckeys into Slurmdbd
database. It assembles codes (one by one) from 2 files to create a
wckey and insert it into the slurm database.


#BATCH slurm-llnl-sync-accounts
%package -n slurm-llnl-sync-accounts
Summary: Script to keep accounts in sync in SlurmDBD
Group: Application/System
Requires: slurm, crontabs
%description -n slurm-llnl-sync-accounts
This package provides a Python script and a cronjob to sync cluster group
members with users and accounts in SlurmDBD.


#BATCH slurmdbd-backup
%package -n slurmdbd-backup
Summary: Tool to backup the SlurmDBD database
Group: Application/System
Requires: mariadb
%description -n slurmdbd-backup
The database is dumped in a local directory with the mysqldump tool.


#%files

%files -n slurm-llnl-generic-scripts-plugin
%defattr(-,root,root,-)
/usr/lib/slurm/generic-scripts/generic-script.sh
/usr/lib/slurm/generic-scripts/Prolog.d
/usr/lib/slurm/generic-scripts/SrunProlog.d
%dir /usr/lib/slurm/generic-scripts/TaskProlog.d
/usr/lib/slurm/generic-scripts/PrologSlurmctld.d
/usr/lib/slurm/generic-scripts/Epilog.d
/usr/lib/slurm/generic-scripts/SrunEpilog.d
%dir /usr/lib/slurm/generic-scripts/TaskEpilog.d
/usr/lib/slurm/generic-scripts/EpilogSlurmctld.d
/usr/lib/slurm/generic-scripts/Epilog.sh
/usr/lib/slurm/generic-scripts/EpilogSlurmctld.sh
/usr/lib/slurm/generic-scripts/Prolog.sh
/usr/lib/slurm/generic-scripts/PrologSlurmctld.sh
/usr/lib/slurm/generic-scripts/SrunEpilog.sh
/usr/lib/slurm/generic-scripts/SrunProlog.sh
/usr/lib/slurm/generic-scripts/TaskEpilog.sh
/usr/lib/slurm/generic-scripts/TaskProlog.sh

%files -n slurm-llnl-generic-scripts-plugin-lgssc
%defattr(-,root,root,-)
/usr/lib/slurm/generic-scripts/TaskProlog.d/kerberos_lustre.sh
/usr/lib/slurm/generic-scripts/TaskEpilog.d/kerberos_lustre.sh

# slurm-llnl-job-submit-plugin
%files -n slurm-llnl-job-submit-plugin
%defattr(-,root,root,-)
%config /etc/slurm/wckeysctl
/usr/lib/slurm/job_submit.lua
/usr/sbin/slurm-gen-qos-conf

#DEPRECATED slurm-llnl-node-health-plugin

#BATCH slurm-llnl-setup-mysql
%files -n slurm-llnl-setup-mysql
%defattr(-,root,root,-)
/usr/sbin/slurm-mysql-setup
%config /etc/slurm/slurm-mysql.conf

#BATCH slurm-llnl-setup-wckeys
%files -n slurm-llnl-setup-wckeys
%defattr(-,root,root,-)
/usr/sbin/slurm-wckeys-setup
/etc/sysconfig/wckeysctl
/etc/cron.d/slurm-llnl-setup-wckeys

#BATCH slurm-llnl-sync-accounts
%files -n slurm-llnl-sync-accounts
/usr/sbin/slurm-sync-accounts
%config /etc/slurm/sync-accounts.conf
%config /etc/cron.d/slurm-llnl-sync-accounts

#BATCH slurmdbd-backup
%files -n slurmdbd-backup
/var/backups/slurmdbd
/var/backups/slurmdbd/database
/usr/sbin/slurmdbd-backup
%config /etc/slurm/slurmdbd-backup.vars

%changelog
* Thu Jan 13 2022 Mathieu Chouquet-Stringer <mathieu-externe.chouquet-stringer@edf.fr> 1.2.8-1el8.edf
- Bump to 1.2.8
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

* Fri Feb 26 2021 Thomas Hamel <thomas-t.hamel@edf.fr> 1.2.6-1el8.edf
- Bump to 1.2.6
- improive kerberos prolog epilog scripts

* Thu Feb 19 2021 Thomas Hamel <thomas-t.hamel@edf.fr> 1.2.5-1el8.edf
- Bump to 1.2.5
- improive kerberos prolog epilog scripts

* Thu Feb 19 2021 Thomas Hamel <thomas-t.hamel@edf.fr> 1.2.4-2el8.edf
- Change version tag to work with jenkins

* Thu Feb 18 2021 Thomas Hamel <thomas-t.hamel@edf.fr> 1.2.4-1el8.edf
- bump to 1.2.4
- Add renewer for lustre kerberos

* Thu Dec 24 2020 Thomas Hamel <thomas-t.hamel@edf.fr> 1.2.2-1el8.edf
- bump to 1.2.2
- Fix epilog to detect job are still running

* Wed Dec 16 2020 Thomas Hamel <thomas-t.hamel@edf.fr> 1.2.1-1el8.edf
- bump to 1.2.1
- wckeys EL8 compatibility

* Thu Dec 10 2020 Thomas Hamel <thomas-t.hamel@edf.fr> 1.2.0-1el8.edf
- bump to 1.2.0
- add kerberos_lustre task prolog
- mark files in /etc as config

* Fri Dec 04 2020 Thomas Hamel <thomas-t.hamel@edf.fr> 1.1.1-1el8.edf
- bump to 1.1.1

* Fri Oct 30 2020 Thomas Hamel <thomas-t.hamel@edf.fr> 1.0.4-1el8.edf
- Add all batch nodes packages and bump to 1.0.4

* Wed Jul 15 2020 Pierre Trespeuch <pierre-externe.trespeuch@edf.fr> 1.0.3-1el8.edf
- Initial RPM release
