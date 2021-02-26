#!/bin/sh

##### Setting up lustre kerberos context
## Set the canonical credential cache path, that is where
## lustre (lgss) will search for the credentials
user_numerical_id=$(id -u)
canonical_ccache="/tmp/krb5cc_${user_numerical_id}"

if [[ ${user_numerical_id} == "x0" ]]
then
  # Root has root squash or not, but he does not need this to
  # access its home
  exit 0
fi

# Find the first lustre mount point
lustre_mountpoint="$(LANG=C mount -t lustre | head -n1 |sed -n "s/.* on \(.*\) type lustre .*/\1/;T;p")"
if [[ -z ${lustre_mountpoint} ]]
then
  # No lustre mountpoint, this is pointless
  exit 0
fi

if [[ -z "$KRB5CCNAME" ]]
then
  # That's not good, we can't do much, if there is already a valid
  # credential cache in the canonical path that might work.
  echo "No KRB5CCNAME defined" | logger -s
  klist >&2
else
  if [[ $KRB5CCNAME != "FILE:${canonical_ccache}" ]]
  then
    # Putting the cache in the canoncial place, cp is a crude tool
    # to do this, delegating a credential would be better
    cp $(echo $KRB5CCNAME | cut -d ":" -f 2) ${canonical_ccache}
  fi
fi

# Launch a background renewer for this canonical cache using auks
#   Permits to talk to the systemctl user instance
export XDG_RUNTIME_DIR="/run/user/${user_numerical_id}"
if ! systemctl --user is-active auks-renewer
then
  systemd-run --user --unit=auks-renewer auks -R loop -C "${canonical_ccache}"
else
  echo "auks-renewer unit is already running" |logger -s
fi

# Put some context in the logs
klist |logger
klist -C "${canonical_ccache}" |logger

# And now the confusing part

# Trying to access lustre, this triggers a new key
#  * If an access was already attempted, the new key will be properly
#    initialized but this access will still fail because of the bad
#    key that will be removed next
#  * If this is the first access, it should succeed
ls ${lustre_mountpoint}  > /dev/null 2>&1

#
# The keyring has an unitialized key, reaping it will force the
# good key to take its place.
keyctl reap >/dev/null 2>&1

