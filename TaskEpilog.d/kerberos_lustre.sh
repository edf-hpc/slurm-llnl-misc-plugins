#!/bin/sh
# This epilog will only log kerberos context
# to help debug ticket validity issues.

##### Setting up lustre kerberos context
user_numerical_id=$(id -u)
canonical_ccache="/tmp/krb5cc_${user_numerical_id}"

# Find the first lustre mount point
lustre_mountpoint="$(LANG=C mount -t lustre | head -n1 |sed -n "s/.* on \(.*\) type lustre .*/\1/;T;p")"
if [[ -z ${lustre_mountpoint} ]]
then
  # No lustre mountpoint, this is pointless
  exit 0
fi

if ! systemctl --user is-active auks-renewer 
then
  echo "auks-renewer unit is not running" |logger
fi
# Put some context in the logs
klist 2>&1 |logger
klist -C "${canonical_ccache}" 2>&1 |logger
