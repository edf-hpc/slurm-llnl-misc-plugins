#!/usr/bin/lua
--[[

SLURM job submit filter for QOS :

This program automatically analyzes properties of submitted jobs and
selects the best QOS to route jobs.
The format of QOS name have to be : <partition>_<QOS name> .
The selection is done with walltime and maxcpus read from sacctmgr command
output.

Copyright :

Copyright (C) 2013 EDF SA

Contact:

CCN - HPC <dsp-cspit-ccn-hpc@edf.fr>
1, Avenue du General de Gaulle
92140 Clamart

Author:

Bruno Agneray <bruno-externe.agneray@edf.fr>

License :

This program is free software; you can redistribute in and/or
modify it under the terms of the GNU General Public License,
version 2, as published by the Free Software Foundation.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
On Calibre systems, the complete text of the GNU General
Public License can be found in `/usr/share/common-licenses/GPL'.

--]]

--########################################################################--
--
--  Define constant
--
--########################################################################--

QOS_SEP = "|"           -- separator for sacctmgr command ouput
QOS_NAME_SEP = "_"      -- separator for QOS name
NULL = 4294967294       -- numeric nil
CORES_PER_NODE=28
ESLURM_INVALID_WCKEY=2057       -- Cf /usr/include/slurm/slurm_errno.h

--########################################################################--
--
--  Define functions
--
--########################################################################--

--========================================================================--

function showstring(key)
        -- If the string key is not define, return the string nil
        -- that is useful to avoid lua error message
        if key == nil then
                return "nil"
        else
                return key
        end
end

--========================================================================--

function addToSet(set, key)
        -- Add an element in the table, if it has not already be added
        -- set  : table where the element is to be added
        -- key  : element to be added
        if set == nil then -- if not exist, set must be created
                set = {}
        end

        if set[key] == nil then -- the key is added if not already added
                table.insert(set, key)
        end
        return set
end

--========================================================================--

function split(inputstr, sep)
        -- Return a table the elements split in a string
        -- inputstr     : string to be split
        -- sep          : separator for split the string
        if sep == nil then -- If no separator, split in word
                sep = "%s"
        end
        t={} ; i=1
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                t[i] = str
                i = i + 1
        end
        return t
end

--========================================================================--

function os.capture(cmd)
        -- Read the output of a system command
        -- cmd  : command to be executed
        local f = assert(io.popen(cmd, 'r'))
        local s = assert(f:read('*a'))
        f:close()
        s = string.gsub(s, '^%s+', '')
        s = string.gsub(s, '%s+$', '')
        s = string.gsub(s, '[\n\r]+', ' ')
        return s
end

--========================================================================--

function to_minute(inputstr)
        -- convert SLURM time format in minute :
        -- inpustr : string should looks like :
        --      minutes, minutes:seconds, hours:minutes:seconds,
        --      days-hours, days-hours:minutes, days-hours:minutes:seconds
        local d,h,m,s
        local t

        if inputstr ~= nil then
                -- Test if a day is indicated (string separated by "-"
                d, t = string.match (inputstr, "^(%d*)-(.*)$")

                if d == nil then -- no day indicated
                        m = string.match (inputstr, "^(%d*)$")
                        if m ~= nil then  -- minutes indicated
                                return m
                        else
                                m, s = string.match (inputstr, "^(%d*):(%d*)$")
                                if m ~= nil and  s ~= nil then -- minutes:seconds indicated
                                        -- seconds ceiled to one minute if greater than 1
                                        return m + math.ceil(s/60)
                                else
                                        h, m, s = string.match (inputstr, "^(%d*):(%d*):(%d*)$")
                                        if h ~= nil and  m ~= nil and s ~= nil then -- hours:minutes:seconds indicated
                                                -- second ceiled to one minute if greater than 1
                                                return h * 60 + m + math.ceil(s/60)
                                        end
                                end
                        end
                else -- day indicated
                        d = d * 24 * 60 --converted to minutes
                        m = string.match (t, "^(%d*)$")
                        if m ~= nil then -- hours indicated
                                return d + m
                        else
                                h, m = string.match (t, "^(%d+):(%d+)$") -- hours:minutes indicated
                                if h ~= nil and  m ~= nil then
                                        return d + h * 60 + m
                                else
                                        h, m, s = string.match (t, "^(%d+):(%d+):(%d+)$") -- hours:minutes:seconds indicated
                                        if h ~= nil and  m ~= nil and s ~= nil then
                                                return d + h * 60 + m + math.ceil(s/60)
                                        end
                                end
                        end
                end
        end
end

--========================================================================--

function build_qos_list ()
        -- Read QOS configuration from sacctmgr command and create a multi-dimension table
        -- qos_list[qos_name][qos_maxcpus][qos_duration] = qos_name
        local qos_list = {}
        local qos_rec = {}
        local qos_name
        local qos_duration
        local qos_maxcpus
        local qos_partition
        local qos_conf = "/etc/slurm-llnl/qos.conf"
        local qos_file

        qos_file = io.open (qos_conf, "r")
        if qos_file == nil then
                -- Read informations from sacctmgr command
                qos_rec = assert (io.popen ("sacctmgr --noheader --parsable show qos format=\"Name,MaxWall,MaxCPUs\" | sort -t'_' -d -k 2 -k 1"))
        else
                -- Read qos_conf file
                qos_rec = assert (io.popen ("cat /etc/slurm-llnl/qos.conf"))
        end

        for line in qos_rec:lines() do
                local t = {}
                -- QOS information
                t = split(line, QOS_SEP)
                qos_name=t[1]
                qos_duration=to_minute(t[2])
                qos_maxcpus=t[3]

                if qos_duration ~= nil and qos_maxcpus ~=nil
                then

                        -- QOS name
                        t = split(qos_name, QOS_NAME_SEP)
                        qos_partition=t[1]

                        qos_list = addToSet(qos_list, qos_partition)
                        qos_list[qos_partition] = addToSet(qos_list[qos_partition], qos_maxcpus)
                        qos_list[qos_partition][qos_maxcpus] = addToSet(qos_list[qos_partition][qos_maxcpus], qos_duration)
                        qos_list[qos_partition][qos_maxcpus][qos_duration] = qos_name
                end
        end -- for loop

        -- Sort  all tables
        if qos_list ~= nil then
                -- table.sort(qos_list, function(a,b) return a < b end) -- sort qos (optional)
                for i, qos in ipairs(qos_list) do
                        if qos_list[qos] ~= nil then
                                table.sort(qos_list[qos], function(a,b) return tonumber(a) < tonumber(b) end) --sort maxcpus
                                for j, maxcpus in ipairs(qos_list[qos]) do
                                        if qos_list[qos][maxcpus] ~= nil then
                                                table.sort(qos_list[qos][maxcpus], function(a,b) return tonumber(a) < tonumber(b) end) --sort duration
                                        end
                                end
                        end
                end
        end
        io.close(qos_rec)
        return qos_list
end

function track_wckey (job_desc, part_list, submit_uid)

        local username
        local cmd = "getent passwd " .. submit_uid .. "| awk -F':' '{print tolower($1)}'"
        username = os.capture(cmd) -- convert uid to logname
        local wckey_conf_file = "/etc/slurm-llnl/wckeysctl/wckeys"
        wckey_conf = io.open (wckey_conf_file, "r")
        local user_exep_file = "/etc/slurm-llnl/wckeysctl/wckeys_user_exception"
        user_exep = io.open (user_exep_file, "r")

        if wckey_conf ~= nil then
                if job_desc.wckey == nil then
                        if user_exep ~= nil then
                                local exep_check = "grep -i -q -x " .. username .. " " .. user_exep_file
                                if os.execute(exep_check) == 0 then
                                        slurm.log_info("slurm_wckey_exeption: job from user:%s/%u without wckey.", username, submit_uid)
                                        return 0
                                end
                        end
                        slurm.log_info("slurm_job_modify: job from user:%s/%u didn't specify any valid wckey.", username, submit_uid)
                        return ESLURM_INVALID_WCKEY
                else
                        -- Convert wckey to lowercase  --
                        if job_desc.wckey ~= nil then
                                job_desc.wckey = string.lower(job_desc.wckey)
                        end
                        local wc_check = "grep -q -x " .. job_desc.wckey .. " " .. wckey_conf_file
                        if os.execute(wc_check) == 0 then
                                slurm.log_info("slurm_job_modify: job from user:%s/%u with wckey=%s.", username, submit_uid, showstring(job_desc.wckey))
                                return 0
                        else
                                slurm.log_info("slurm_job_modify: job from user:%s/%u did specify an invalid wckey:%s", username, submit_uid, showstring(job_desc.wckey))
                                return ESLURM_INVALID_WCKEY
                        end
                end
        else
                return 0
        end
end

--########################################################################--
--
--  SLURM job_submit/lua interface:
--
--########################################################################--

function slurm_job_submit ( job_desc, part_list, submit_uid )

        status=track_wckey (job_desc, part_list, submit_uid)
        if status ~= 0 then
                return status
        end

        local username
        local qos_list = build_qos_list()
        local maxtime
        local maxcpus
        local cmd =  "getent passwd " .. submit_uid .. "| awk -F':' '{print tolower($1)}'"
        username = os.capture(cmd) -- convert uid to logname

        -- QOS set by user. In this case, the script simply sets the partition
        -- accordingly.
        if job_desc.qos ~= nil then

                local t = split(job_desc.qos, QOS_NAME_SEP)

                partition = t[1]

                if job_desc.partition == nil then
                        job_desc.partition = partition
                end
        else
                -- The user did not set the QOS explicitely

                -- If not set by user, set hard-coded timelimit
                if job_desc.time_limit == NULL then -- no time limit
                        job_desc.time_limit = 60 -- 1 heure
                end
                -- If not set by user, set hard-coded min cpus
                if job_desc.min_cpus == nil then -- no cpu limit
                        job_desc.min_cpus = 1
                end

                -- If jobs are exclusive, multiply job min_nodes with CORES_PER_NODE
                -- check if the user explicitely specified a number of nodes in its
                -- submission params otherwise the job_desc.min_nodes is equal to 2^32
                -- and it would be totally irrelevant to multiply it to CORES_PER_NODE
                -- for considered_min_cpus... That implies that if the user used a
                -- combination of -n,--ntasks and --exclusive, the exclusive is simply
                -- ignored.
                considered_min_cpus = job_desc.min_cpus
                if job_desc.shared == 0 and job_desc.min_nodes ~= NULL then
                        considered_min_cpus = job_desc.min_nodes * CORES_PER_NODE
                end

                if job_desc.partition ~= nil then
                        slurm.log_info("slurm_job_submit: partition %s specified by user.", job_desc.partition)
                else
                        -- If the user did not set the partition, set the default
                        -- partition in slurm configuration
                        for name, part in pairs(part_list) do
                                if part.flag_default == 1 then
                                        job_desc.partition = part.name
                                        break
                                end
                        end
                end

                -- Find the first QOS in qos_list that matches jobs cpus and
                -- and time limit
                if qos_list ~= nil then
                        for i, part in pairs (qos_list) do
                                -- Restrict to QOS compatible with the partition only
                                if job_desc.partition == nil or job_desc.partition == part then

                                        if qos_list[part] ~= nil then
                                                for j, maxcpus in ipairs(qos_list[part]) do
                                                        if considered_min_cpus <= tonumber(maxcpus) and (job_desc.max_nodes == NULL or job_desc.max_nodes <= tonumber(maxcpus) / CORES_PER_NODE) then

                                                                found_maxtime = 0
                                                                if qos_list[part][maxcpus] ~= nil then
                                                                        for k, qos_maxtime in ipairs(qos_list[part][maxcpus]) do
                                                                                if job_desc.time_limit <= tonumber(qos_maxtime) then
                                                                                        found_maxtime = qos_maxtime
                                                                                        break
                                                                                end
                                                                        end

                                                                        if found_maxtime ~= 0 then
                                                                                job_desc.qos = qos_list[part][maxcpus][found_maxtime]
                                                                                job_desc.partition = part
                                                                                break
                                                                        end
                                                                end
                                                        end
                                                end
                                        end
                                end
                        end
                end

        end

        slurm.log_info("slurm_job_submit: job from user:%s/%u minutes:%u cores:%u shared:%u partition:%s QOS:%s", username, submit_uid, job_desc.time_limit, job_desc.min_cpus, job_desc.shared, showstring(job_desc.partition), showstring(job_desc.qos))

        return slurm.SUCCESS
end

--========================================================================--

function slurm_job_modify ( job_desc, job_rec, part_list, modify_uid )
        return slurm.SUCCESS
end

slurm.log_info("initialized")

return slurm.SUCCESS
