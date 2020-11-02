# Configuration Logic
%define name slurm-llnl-misc-plugins
%define version 1.1.0
%define debug_package %{nil}

# Main preamble
Summary: Miscelaneous plugins for Slurm open source scheduler
Name: %{name}
Version: %{version}
Release:  1%{?dist}.edf
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
/usr/lib/slurm/generic-scripts/TaskProlog.d
/usr/lib/slurm/generic-scripts/PrologSlurmctld.d
/usr/lib/slurm/generic-scripts/Epilog.d
/usr/lib/slurm/generic-scripts/SrunEpilog.d
/usr/lib/slurm/generic-scripts/TaskEpilog.d
/usr/lib/slurm/generic-scripts/EpilogSlurmctld.d
/usr/lib/slurm/generic-scripts/Epilog.sh
/usr/lib/slurm/generic-scripts/EpilogSlurmctld.sh
/usr/lib/slurm/generic-scripts/Prolog.sh
/usr/lib/slurm/generic-scripts/PrologSlurmctld.sh
/usr/lib/slurm/generic-scripts/SrunEpilog.sh
/usr/lib/slurm/generic-scripts/SrunProlog.sh
/usr/lib/slurm/generic-scripts/TaskEpilog.sh
/usr/lib/slurm/generic-scripts/TaskProlog.sh

# slurm-llnl-job-submit-plugin
%files -n slurm-llnl-job-submit-plugin
%defattr(-,root,root,-)
/etc/slurm/wckeysctl
/usr/lib/slurm/job_submit.lua
/usr/sbin/slurm-gen-qos-conf

#DEPRECATED slurm-llnl-node-health-plugin

#BATCH slurm-llnl-setup-mysql
%files -n slurm-llnl-setup-mysql
%defattr(-,root,root,-)
/usr/sbin/slurm-mysql-setup
/etc/slurm/slurm-mysql.conf

#BATCH slurm-llnl-setup-wckeys
%files -n slurm-llnl-setup-wckeys
%defattr(-,root,root,-)
/usr/sbin/slurm-wckeys-setup
/etc/sysconfig/wckeysctl
/etc/cron.d/slurm-llnl-setup-wckeys

#BATCH slurm-llnl-sync-accounts
%files -n slurm-llnl-sync-accounts
/usr/sbin/slurm-sync-accounts
/etc/slurm/sync-accounts.conf
/etc/cron.d/slurm-llnl-sync-accounts

#BATCH slurmdbd-backup
%files -n slurmdbd-backup
/var/backups/slurmdbd
/var/backups/slurmdbd/database
/usr/sbin/slurmdbd-backup
/etc/slurm/slurmdbd-backup.vars

%changelog
* Fri Oct 30 2020 Thomas Hamel <thomas-t.hamel@edf.fr> 1.0.4-1el8.edf
- Add all batch nodes packages and bump to 1.0.4

* Wed Jul 15 2020 Pierre Trespeuch <pierre-externe.trespeuch@edf.fr> 1.0.3-1el8.edf
- Initial RPM release
