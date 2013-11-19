#!/bin/bash

hasElement () {
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
}

info () {
  if [ ! -z $SLURM_GENERIC_SCRIPTS ]; then
    echo "I: $1"
  fi
}

warn () {
  echo "W: $1"
}

error () {
  echo "E: $1"
  exit 1
}

NAME="$(basename $0 .sh)"
PATHD="$(dirname $0)"

SCRIPTS=(Prolog SrunProlog TaskProlog PrologSlurmctld Epilog SrunEpilog TaskEpilog EpilogSlurmctld)

if hasElement "${NAME}" "${SCRIPTS[@]}"; then
  DIRNAME="${PATHD}/${NAME}.d"
  info "Directory for ${NAME} scripts in ${DIRNAME}"
  if [ -d "${DIRNAME}" ]; then
    for script in `find ${DIRNAME} -type f -or type l -executable -print 2>/dev/null | sort`; do
      info "Executing $script..."
      $script
      if [ "$?" -ne "0" ]; then
        warn "script $script failed!"
      fi
    done
  else
    error "${DIRNAME} doesn't exist!"
  fi
else
  error "Unknown script type ${NAME}!";
fi
