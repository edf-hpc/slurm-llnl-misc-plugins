#!/bin/bash 
#####################################################################
# This script will be executed on each compute node to verify 
# that the node is working properly. 
#####################################################################
# Copyright (C) 2013 EDF SA                                           
# Contact:                                                            
#       CCN - HPC <dsp-cspit-ccn-hpc@edf.fr>                          
#       1, Avenue du General de Gaulle                                
#       92140 Clamart                                                 
#                                                                     
#Authors: Antonio J. Russo <antonio-externe.russo@edf.fr>             
#This program is free software; you can redistribute in and/or        
#modify it under the terms of the GNU General Public License,         
#version 2, as published by the Free Software Foundation.             
#This program is distributed in the hope that it will be useful,      
#but WITHOUT ANY WARRANTY; without even the implied warranty of       
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        
#GNU General Public License for more details.                         
#On Calibre systems, the complete text of the GNU General             
#Public License can be found in `/usr/share/common-licenses/GPL'.     
##################################################################### 

PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"
DEFCFG=/etc/default/checknodehealth
STATUS=0
REASONS=""
NETWK=0

slurm_state()
{
	STATE=$(sinfo --noheader --node=$(hostname -s) --format=%t)
       	case ${STATE} in
                'alloc'|'idle'|'mix')
                        return 0
                        ;;
                *)
                        return 1
                        ;;
        esac
}

numbers_proc ()
{
        PHYSICAL=$(grep -i "physical id" /proc/cpuinfo | sort -u | wc -l)
        CPUCORES=$(grep -i "cpu cores"   /proc/cpuinfo | sort -u | awk -F ": " '{print $2}')
        REALPROC=$(grep -i "processor"   /proc/cpuinfo | sort -u | wc -l)
        let "NOHTPROC = PHYSICAL * CPUCORES"

        if [ ${NOHTPROC} -ne ${REALPROC} ]
        then
		STATUS=1
		MSG="Unexpected number of processors"
		REASONS="${MSG}"
        fi
}


mount_points ()
{
	for volume in ${MOUNTS}
	do
		mountpoint -q ${volume}  	
		if [ ${?} -ne 0 ]
        	then
			STATUS=1
                	MSG="${volume} umounted"
                	REASONS="${REASONS:+$REASONS, }${MSG}"
		else
			USAGE=$(df -h | grep ${volume} | cut -c 41-42)
			if [ ${USAGE} -gt ${FSLIMIT} ]
			then
				STATUS=1
                        	MSG="${volume} usage ${USAGE}%"
                        	REASONS="${REASONS:+$REASONS, }${MSG}"
			fi
        	fi
	done
}

auth_ldap ()
{
	PMUSERS=( $(members ${PMGROUP} 2> /dev/null) ) 
	if [ ${#PMUSERS[@]} -gt 0 ]
	then
		IRD=$(shuf -i 0-${#PMUSERS[@]}  -n 1)
		RDUSER=${PMUSERS[${IRD}]}
	else
		RDUSER='userdoesnotexist'
	fi
	id ${RDUSER} &> /dev/null 
	if [ ${?} -ne 0 ]
	then
		STATUS=1 
		MSG="LDAP server is unavailable" 
		REASONS="${REASONS:+$REASONS, }${MSG}"
	fi
}

pkgs_inst ()
{
	PKGSINST=$(dpkg -l | grep ^ii | wc -l)

	if [ ${PKGSINST} -lt ${NRPKGS} ] 
	then
                STATUS=1
		MSG="Unexpected number of packages"
		REASONS="${REASONS:+$REASONS, }${MSG}"
	
	fi 

	if [ $(uname -r) != ${KERNELVER} ]
	then
		STATUS=1
                MSG="Unexpected kernel version"
                REASONS="${REASONS:+$REASONS, }${MSG}"
	fi
}

network_up ()
{
	ping -c 1 ${2} &> /dev/null || ping -c 1 ${3} &> /dev/null
	
	if [ ${?} -ne 0 ]
        then
                STATUS=1
		NETWK=1
                MSG="${1} is down"
                REASONS="${REASONS:+$REASONS, }${MSG}"
	else
		if [ ${1} == "Infiniband" ]
		then
			if [ $(ibstat | grep 'Rate' | cut -c 9-10) -ne ${IBLIMIT} ]
        		then
                		STATUS=1
                		MSG="${1} rate is is less than ${IBLIMIT}"
                		REASONS="${REASONS:+$REASONS, }${MSG}"
			fi
		fi
        fi
}

ntp_sync ()
{
	ntpq -p ${2} &> /dev/null
	if [ ${?} -ne 0 ]
        then
                STATUS=1
                MSG="NTP server is unavailable"
                REASONS="${REASONS:+$REASONS, }${MSG}"
        fi
}

check_node () 
{
	numbers_proc
	pkgs_inst
	network_up "Ethernet" ${ETHMASTER} ${ETHBACKUP} 	
	network_up "Infiniband" ${IBMASTER} ${IBBACKUP}
	if [ ${NETWK} -eq 0 ]
	then 	
		mount_points
		auth_ldap
		ntp_sync
	fi

	if [[ ${STATUS} -eq 0 ]]
	then
		REASONS="Node OK"
	fi
}

drain_node ()
{
	if [[ ${STATUS} -eq 1 ]]
	then
		scontrol update NodeName=$(hostname -s) State=DRAIN Reason="${REASONS}"
	fi

}

if [ -f ${DEFCFG} ]
then
	source ${DEFCFG}
else
	exit 1	
fi

case ${1} in
	--no-slurm)
		check_node
		echo ${REASONS}
	;;
	
	*)
		if slurm_state
		then
			check_node
			drain_node
		fi
	;;
esac

exit ${STATUS} 
