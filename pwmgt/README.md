# Slurm power management utilities

## Architecture

This set of slurm power management utilities is composed of:

* `slurm-pwmgt-nodes` script with its 2 start/stop wrappers designed to be run
  by Slurm workload manager controller daemon. This script run ipmitool utility
  to start nodes and SSH command to stop nodes, with help of ClusterShell
  library for parallelization. This script has a configuration file located in
  `/etc/slurm/pwmgt/main.conf`.
* `slurm-pwmgt-stop-wrapper`, a wrapper of suspend/stop OS commands designed to
  be run as SSH forced command. This script has a configuration file located in
  `/etc/slurm/pwmgt/stop-wrapper.conf`. Default values should be fine for
  most systems though.

The `slurm-pwmgt-nodes` is expected to connect as root on compute with a
dedicated SSH key pair. The public key must be associated to the stop wrapper
configured as a forced command in root's `authorized_keys` file. This way, slurm
is not granted to run anything else but expected commands to stop the nodes.

## Install

On slurm controller server:

* Install the `slurm-pwmgt-nodes` script with:

```
# apt-get install slurm-pwmgt-nodes
```

* Edit `/etc/slurm/pwmgt/main.conf` to fit your requirements

* Protect IPMI password with restricted files permissions:

```
# chmod 0640 /etc/slurm/pwmgt/main.conf
# chown slurm: /etc/slurm/pwmgt/main.conf
```

* Generate a new pair of SSH keys without passphrase:

```
# ssh-keygen -b 2048 -t rsa -N '' -C slurm@nodes \
  -f /etc/slurm/pwmgt/id_rsa_slurm
```

* Set ownership of the keys to slurm user:

```
# chown slurm: /etc/slurm/pwmgt/id_rsa*
```

On compute nodes:

* Install the stop wrapper:

```
# apt-get install slurm-pwmgt-stop-wrapper
```

* Add the public key in root's `authorized_keys` file on all compute nodes with
  the stop wrapper as forced command associated to the key:

```
command="/usr/lib/slurm-pwmgt/exec/slurm-stop-wrapper" ssh-rsa <pubkey> slurm@nodes
```

In Slurm configuration:

* Set the following parameters:

```
SuspendTime=60
SuspendProgram=/usr/lib/slurm-pwmgt/exec/slurm-suspend-nodes
ResumeProgram=/usr/lib/slurm-pwmgt/exec/slurm-resume-nodes
```

And adjust timeouts.

* Deploy new `slurm.conf` everywhere
* Restart `slurmctld`
* Finally run:

```
# scontrol reconfig
```
