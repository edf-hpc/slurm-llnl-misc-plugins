#!/bin/bash 
STATUS=$(sinfo --noheader --node=$(hostname -s) --format=%t)

#alloc_or_idle()
#{
#        case ${STATUS} in
#                'alloc'|'idle')
#                        return 0
#                        ;;
#                *)
#                        return 1
#                        ;;
#        esac
#}

#control_HT()
#{
#        PHYSICAL=$(grep -i "physical id" /proc/cpuinfo | sort -u | wc -l)
#        CPUCORES=$(grep -i "cpu cores"   /proc/cpuinfo | sort -u | awk -F ": " '{print $2}')
#        REALPROC=$(grep -i "processor"   /proc/cpuinfo | sort -u | wc -l)
#        let "NOHTPROC = PHYSICAL * CPUCORES"
#
#        if [[ ${NOHTPROC} -eq ${REALPROC} ]]
#        then
#                rt=0
#        elif [[ ${NOHTPROC} -eq $(echo "${REALPROC} / 2") ]]
#        then
#                rt=1
#        else
#                rt=-1
#        fi
#        return $rt
#}

#MOUNTS=$(grep -c nfs /proc/mounts)
#if [ ${MOUNTS} -ne "2" ]; then
#  alloc_or_idle && {
#    scontrol update NodeName=$(hostname -s) State=DRAIN Reason="NFS not mounted"
#    exit 1
#  }
#fi

#df --type=nfs 2>&1 | grep -q "Stale NFS file handle"
#RESULT=$?
 
#if [ $RESULT -eq 0 ]; then
#  echo "State NFS down ib0"
#  alloc_or_idle && {
#    scontrol update NodeName=$(hostname -s) State=DRAIN Reason="Stale GPFS down ib0"
#    exit 1
#  }
#fi

#control_HT

#if [ $? -ne 0 ]; then
#  echo "Unexpected number of processors"
#  alloc_or_idle && {
#    scontrol update NodeName=$(hostname -s) State=DRAIN Reason="Unexpected number of processors"
#    exit 1
#  }
#fi

exit 0
