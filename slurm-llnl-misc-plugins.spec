# Configuration Logic
%define name slurm-llnl-misc-plugins
%define version 1.0.3
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
# slurm-lnll-generic-scripts-plugin
install -d %{buildroot}/usr/lib/slurm/generic-scripts
install -m 755 generic-script.sh %{buildroot}/usr/lib/slurm/generic-scripts
for step in Prolog SrunProlog TaskProlog PrologSlurmctld Epilog SrunEpilog TaskEpilog EpilogSlurmctld 
do	   
    install -d %{buildroot}/usr/lib/slurm/generic-scripts/${step}.d
    ln -s /usr/lib/slurm/generic-scripts/generic-script.sh %{buildroot}/usr/lib/slurm/generic-scripts/${step}.sh
done
install -m 755 Epilog.d/00_clean %{buildroot}/usr/lib/slurm/generic-scripts/Epilog.d

# slurm-lnll-job-submit-plugin
# mkdir -p %{buildroot}/etc/slurm-llnl/wckeysctl
# mkdir -p %{buildroot}/etc/default
# mkdir -p %{buildroot}/usr/sbin
# install -m 755 job_submit/job_submit.lua %{buildroot}/usr/lib/slurm
# install -m 755 job_submit/slurm-gen-qos-conf %{buildroot}/usr/sbin

%clean
rm -rf %{buildroot}

%description
Miscelaneous plugins for Slurm open source scheduler

#%files

# slurm-lnll-generic-scripts-plugin package
%package -n slurm-lnll-generic-scripts-plugin
Summary: Generic Prolog and Epilog scripts for Slurm
Group: Application/System 
%description -n slurm-lnll-generic-scripts-plugin
The job scheduler Slurm can execute so called Prolog and Epilog scripts
at different stages of each job. For each stage, one script has to appear
in Slurm\'s configuration file.
This package provides a generic script that can be linked to in order to
behave as a (Pro|Epi)log script using an associated (Pro|Epi)log.d directory
next to it. The latter should contain executable scripts that will be run
for the specified stage.

%files -n slurm-lnll-generic-scripts-plugin
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
# %package -n slurm-lnll-job-submit-plugin
# Requires: slurm-wlm-basic-plugins >= 14.11, slurm-llnl-setup-wckeys >= 0.7.11, python3
# Summary: Lua plugin for routing jobs in approriate defined QOSes
# Group: Application/System 
# %description -n slurm-lnll-job-submit-plugin
# This package provides a lua script for routing jobs in appropriate QOSes
# depending on the compute resources asked by the job.

# %files -n slurm-lnll-job-submit-plugin
# %defattr(-,root,root,-)
# %dir /etc/slurm-llnl/wckeysctl
# %dir /etc/default
# %dir /usr/lib/slurm
# %dir /usr/sbin
# /usr/lib/slurm/job_submit.lua
# /usr/sbin/slurm-gen-qos-conf


#slurm-llnl-node-health-plugin

#slurm-llnl-setup-mysql

#slurm-llnl-setup-wckeys

#slurm-llnl-sync-accounts

#slurm-pwmgt-nodes

#slurm-pwmgt-stop-wrapper

#slurm-admin-utils

#slurm-unkstep-program




%changelog
* Tue Jul 15 2020 Pierre Trespeuch <pierre-externe.trespeuch@edf.fr> 1.0.3-1el8.edf
- Initial RPM release








     






                                                  
