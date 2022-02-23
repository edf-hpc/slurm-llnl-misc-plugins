#!/usr/bin/lua
--
-- SLURM job submit filter for QOS:
--
-- This program automatically analyzes properties of submitted jobs and
-- selects the best QOS to route jobs.
--
-- Name of QOSes has to match this format: <partition>_<max_cores>_<walltime>.
--
-- Copyright: (C) 2013-2017 EDF SA
--
-- Contact:
--
-- CCN - HPC <dsp-cspit-ccn-hpc@edf.fr>
-- 1, Avenue du General de Gaulle
-- 92140 Clamart
--
-- License :
--
-- This program is free software; you can redistribute in and/or modify
-- it under the terms of the GNU General Public License, version 2, as
-- published by the Free Software Foundation.  This program is
-- distributed in the hope that it will be useful, but WITHOUT ANY
-- WARRANTY; without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
-- for more details.  On Calibre systems, the complete text of the GNU
-- General Public License can be found in
-- `/usr/share/common-licenses/GPL'.

--########################################################################--
--
--  Define functions
--
--########################################################################--

--========================================================================--

function sorted_keys(dict)
   keys = {}
   for k in pairs(dict) do
      table.insert(keys, k)
   end
   table.sort(keys)
   return keys
end

--========================================================================--

function split(str, pat)
   -- Return a table the elements split in a string
   -- str   : string to be split
   -- sep   : separator for split the string
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local last_end = 1
   if pat == '' then
       table.insert(t, str)
       return t
   end
   local s, e = str:find(pat, last_end)
   while s do
      if s ~= last_end then
         cap = str:sub(last_end, s - 1)
         table.insert(t, cap)
      else
         table.insert(t, '')
      end
      last_end = e+1

      s, e = str:find(pat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   else
      -- str ends with pat
      table.insert(t, '')
   end
   return t
end

--========================================================================--

function has_value (tab, val)
   -- Returns true if tab has val, false otherwise.
   -- tab: search table
   -- val: value to look for
   for index, value in ipairs (tab) do
      if value == val then
         return true
      end
   end

   return false
end

--========================================================================--

function to_minute(inputstr)
   -- convert SLURM time format in minute :
   -- inpustr : string should looks like :
   --   minutes, minutes:seconds, hours:minutes:seconds,
   --   days-hours, days-hours:minutes, days-hours:minutes:seconds
   local d,h,m,s
   local t

   if inputstr == nil then
      return 0
   end
   -- Test if a day is indicated (string separated by "-"
   d, t = string.match(inputstr, "^(%d+)-(.+)$")

   if d == nil then -- no day indicated
      m = string.match(inputstr, "^(%d+)$")
      if m ~= nil then  -- minutes indicated
         return m
      else
         m, s = string.match(inputstr, "^(%d+):(%d+)$")
         if m ~= nil and s ~= nil then -- minutes:seconds indicated
            -- seconds ceiled to one minute if greater than 1
            return m + math.ceil(s/60)
         else
            h, m, s = string.match(inputstr, "^(%d+):(%d+):(%d+)$")
            if h ~= nil and m ~= nil and s ~= nil then -- hours:minutes:seconds indicated
               -- second ceiled to one minute if greater than 1
               return h * 60 + m + math.ceil(s/60)
            end
         end
      end
   else -- day indicated
      d = d * 24 * 60 --converted to minutes
      h = string.match(t, "^(%d+)$")
      if h ~= nil then -- hours indicated
         return d + h * 60
      else
         h, m = string.match(t, "^(%d+):(%d+)$") -- hours:minutes indicated
         if h ~= nil and m ~= nil then
            return d + h * 60 + m
         else
            h, m, s = string.match(t, "^(%d+):(%d+):(%d+)$") -- hours:minutes:seconds indicated
            if h ~= nil and m ~= nil and s ~= nil then
               return d + h * 60 + m + math.ceil(s/60)
            end
         end
      end
   end
   return 0
end

--========================================================================--

function build_qos_list ()
   -- Read QOS configuration from sacctmgr command and create a multi-dimension table
   -- qos_list[qos_partition][qos_maxcpus][qos_duration][qos_name] = [account_1, ..., account_n]
   -- qos[qos_name] = {
   --   accounts: [account_1, ..., account_n],
   --   duration: 1234,
   --   maxcpus: 1234
   --   partition: somepart,
   -- }
   local qos_list = {}
   local qos = {}
   local qos_rec = {}
   local qos_name
   local qos_duration
   local qos_maxcpus
   local qos_partition
   local qos_file

   if not file_exists(QOS_CONF) then
      slurm.log_info("build_qos_list: qos file %s does not exist, failed to build QOS list",
                     QOS_CONF)
      return nil
   end

   -- Read qos_conf file
   qos_rec = assert (io.open (QOS_CONF, 'r'))

   for line in qos_rec:lines() do
      local t = {}
      -- QOS information
      t = split(line, QOS_SEP)
      qos_name = t[1]
      qos_duration = to_minute(t[2])
      qos_maxcpus = t[3]
      if qos_maxcpus == nil or qos_maxcpus == '' then
         qos_maxcpus = INFINITE
      else
         qos_maxcpus = tonumber(qos_maxcpus)
      end
      accounts = split(t[4], ACCOUNTS_SEP)

      if qos_duration == '' then
         qos_duration = to_minute(4000000000)
      else
         qos_duration = tonumber(qos_duration)
      end

      if qos_duration ~= nil and qos_maxcpus ~=nil
      then
         -- QOS name
         t = split(qos_name, QOS_NAME_SEP)
         qos_partition = t[1]

         qos[qos_name] = {
            accounts  = accounts,
            duration  = qos_duration,
            maxcpus   = qos_maxcpus,
            partition = qos_partition,
         }

         if qos_list[qos_partition] == nil then
            qos_list[qos_partition] = {}
         end
         if qos_list[qos_partition][qos_maxcpus] == nil then
            qos_list[qos_partition][qos_maxcpus] = {}
         end
         if qos_list[qos_partition][qos_maxcpus][qos_duration] == nil then
            qos_list[qos_partition][qos_maxcpus][qos_duration] = {}
         end
         qos_list[qos_partition][qos_maxcpus][qos_duration][qos_name] = accounts
      end
   end -- for loop

   io.close(qos_rec)

   return qos_list, qos
end

-- see if the file exists
function file_exists(file)
   local f = io.open(file, "rb")
   if f then f:close() end
   return f ~= nil
end

-- search for line in file, return true if present, false otherwise
function line_present(file, search)
   for line in io.lines(file) do
      if search == line then
         return true
      end
  end
  return false
end

-- check wckey among WCKEY_CONF_FILE and WCKEY_USER_EXCEPTION_FILE
function track_wckey (job_desc, part_list, submit_uid)
   username = job_desc.username
   -- if WCKEY_CONF_FILE does not exist, return OK
   if not file_exists(WCKEY_CONF_FILE) then
     return 0
   end

   if job_desc.wckey == nil then
      if file_exists(WCKEY_USER_EXCEPTION_FILE) and line_present(WCKEY_USER_EXCEPTION_FILE, username) then
         slurm.log_info("track_wckey: job from user:%s/%u has a valid wckey exception.",
            username, submit_uid)
         return 0
      end
      -- if WCKEY_USER_EXCEPTION_FILE does not exist or username name not found, return wckey error
      slurm.log_info("track_wckey: job from user:%s/%u didn't specify any valid wckey.",
         username, submit_uid)
      return ESLURM_INVALID_WCKEY
   else
     -- Convert wckey to lowercase  --
     job_desc.wckey = string.lower(job_desc.wckey)
     if line_present(WCKEY_CONF_FILE, job_desc.wckey) then
        -- wckey present in file, return OK
        slurm.log_info("track_wckey: job from user:%s/%u with wckey=%s.",
           username, submit_uid, tostring(job_desc.wckey))
        return 0
     else
        -- wckey not found, return wckey error
        slurm.log_info("track_wckey: job from user:%s/%u did specify an invalid wckey:%s",
           username, submit_uid, tostring(job_desc.wckey))
        return ESLURM_INVALID_WCKEY
     end
   end

end

-- log and return information to the user
function log_error(s, ...)
   local msg = s:format(...)
   slurm.log_info(msg)
   slurm.user_msg(msg)
end

--########################################################################--
--
--  Define main parameters (can be overriden in conf_file)
--
--########################################################################--

CONF_DIR       = '/etc/slurm'
QOS_CONF       = CONF_DIR .. "/qos.conf"
QOS_SEP        = "|"         -- separator for sacctmgr command ouput
QOS_NAME_SEP   = "_"         -- separator for QOS name
ACCOUNTS_SEP   = ","         -- separator for accounts
NULL           = 4294967294  -- numeric nil
INFINITE       = 4294967294  -- max unsigned 32 bits integer value for slurm
CORES_PER_NODE = 4
ENFORCE_ACCOUNT = false      -- check qos/account compatibility, default to no
JOB_NAME_REGEX  = "^[a-zA-Z0-9_:.-]+$"
JOB_NAME_DESCRIPTION = "alphanumeric characters ('a-z', 'A-Z' and '0-9') plus '-', '_', '.' and ':'"
JOB_NAME_MAXLEN = 40

-- cf. slurm/slurm_errno.h
ESLURM_INVALID_WCKEY = 2057
ESLURM_INVALID_QOS = 2066

WCKEY_CONF_FILE = CONF_DIR .. "/wckeysctl/wckeys"
WCKEY_USER_EXCEPTION_FILE = CONF_DIR .. "/wckeysctl/wckeys_user_exception"

conf_file = CONF_DIR .. "/job_submit.conf"
conf_fh = io.open (conf_file, "r")
if conf_fh == nil then
   slurm.log_info("slurm_job_modify: No readable %s found!", conf_file)
else
   io.close(conf_fh)
   dofile(conf_file)
end

--########################################################################--
--
--  SLURM job_submit/lua interface:
--
--########################################################################--

function slurm_job_submit ( job_desc, part_list, submit_uid )

   status = track_wckey(job_desc, part_list, submit_uid)
   if status ~= 0 then
      return status
   end

   if string.match(job_desc.name, JOB_NAME_REGEX) == nil then
      log_error("slurm_job_submit: job name %s doesn't match the following: %s",
         job_desc.name, JOB_NAME_DESCRIPTION)
      return slurm.ERROR
   end

   if string.len(job_desc.name) > JOB_NAME_MAXLEN then
      log_error("slurm_job_submit: job name %s length (%d) is longer than allowed (%d)",
         job_desc.name, string.len(job_desc.name), JOB_NAME_MAXLEN)
      return slurm.ERROR
   end

   local qos_list, qos = build_qos_list()
   -- if unable to build QOS list, return ESLURM_INVALID_QOS
   if qos_list == nil then
      log_error("slurm_job_submit: cannot build QoS list")
      return ESLURM_INVALID_QOS
   end

   local maxtime
   local maxcpus

   -- If not set by user, set hard-coded timelimit
   if job_desc.time_limit == NULL then -- no time limit
      job_desc.time_limit = 60 -- 1 heure
   end

   -- QOS set by user. In this case, the script simply sets the partition
   -- accordingly.
   if job_desc.qos ~= nil then
      if string.find(job_desc.qos, QOS_NAME_SEP) then
         local t = split(job_desc.qos, QOS_NAME_SEP)

         partition = t[1]
      else
         partition = nil
      end

      if job_desc.partition == nil then
         if partition == nil then
            log_error("slurm_job_submit: QoS %s was specified but no partition and we cannot deduce it from the QoS",
               job_desc.qos)
            return ESLURM_INVALID_QOS
         end
         job_desc.partition = partition
      -- if we have a partition for the job, checks it matches the QoS
      -- only if it's a QoS with QOS_NAME_SEP
      elseif partition ~= nil and job_desc.partition ~= partition then
         log_error("slurm_job_submit: partition %s specified by user doesn't match QOS %s",
            job_desc.partition, job_desc.qos)
         return ESLURM_INVALID_QOS
      end
   else
      -- The user did not set the QOS explicitely

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
      if job_desc.shared == 0 then
         -- Set minimum requested nodes to avoid errors with message: Job has invalid qos
         -- This makes "-N 1" the default for exclusive jobs, unless overwritten by the user.
         if job_desc.min_nodes == NULL then
            job_desc.min_nodes = 1
         end
         considered_min_cpus = job_desc.min_nodes * CORES_PER_NODE
      end

      if job_desc.partition ~= nil then
         slurm.log_info("slurm_job_submit: partition %s specified by user.", job_desc.partition)
      else
         -- If the user did not set the partition, set the default
         -- partition in slurm configuration
         for _, part in pairs(part_list) do
            if part.flag_default == 1 then
               job_desc.partition = part.name
               break
            end
         end
         if job_desc.partition == nil then
            log_error("slurm_job_submit: couldn't find a default partition")
            return slurm.ERROR
         end
         slurm.log_info("slurm_job_submit: using default partition %s.", job_desc.partition)
      end

      -- if ENFORCE_ACCOUNT is true and job account is not specified, set its
      -- value to user's default account for later processing.
      if ENFORCE_ACCOUNT then
          if job_desc.account == nil then
             if job_desc.default_account == nil then
                slurm.log_info("slurm_job_submit: user %s has no default account, unable to assign default account.",
                   job_desc.user_name)
                return slurm.ESLURM_INVALID_ACCOUNT
             else
                slurm.log_info("slurm_job_submit: no account specified by user %s, using default account %s.",
                   job_desc.user_name, job_desc.default_account)
                job_desc.account = job_desc.default_account
             end
          else
             slurm.log_info("slurm_job_submit: account %s specified by user %s.", job_desc.account, job_desc.user_name)
          end
      end

      if qos_list[job_desc.partition] == nil then
         log_error("slurm_job_submit: no QoS exists for partition %s", job_desc.partition)
         return slurm.ERROR
      end

      found_qos_name = nil

      -- Find the first QOS in qos_list that matches jobs cpus and
      -- and time limit
      for _, maxcpus in ipairs(sorted_keys(qos_list[job_desc.partition])) do
        maxcpu_part = qos_list[job_desc.partition][maxcpus]
        if maxcpu_part == nil then
          goto continue_maxcpus
        end

        if considered_min_cpus > maxcpus then
          goto continue_maxcpus
        end
        if job_desc.max_nodes ~= NULL and job_desc.max_nodes > maxcpus / CORES_PER_NODE then
          goto continue_maxcpus
        end

        for _, maxduration in ipairs(sorted_keys(maxcpu_part)) do
          maxduration_part = maxcpu_part[maxduration]
          if job_desc.time_limit > maxduration then
            goto continue_maxduration
          end

          for qos_name, accounts in pairs(maxduration_part) do
            -- check the job account is allowed in qos accounts if ENFORCE_ACCOUNT is true
            if not ENFORCE_ACCOUNT or has_value(accounts, job_desc.account) then
              found_qos_name = qos_name
              break
            end
          end
          if found_qos_name ~= nil then
            break
          end
          ::continue_maxduration::
        end
        if found_qos_name ~= nil then
           break
        end
        ::continue_maxcpus::
     end

     if found_qos_name ~= nil then
        slurm.log_info("slurm_job_submit: finally setting qos %s", found_qos_name)
        job_desc.qos = found_qos_name
     else
        log_error("slurm_job_submit: couldn't find a QoS match")
        return ESLURM_INVALID_QOS
     end
   end

   -- check time limit
   if qos[job_desc.qos] ~= nil and qos[job_desc.qos]['duration'] ~= nil and
         job_desc.time_limit ~= nil and job_desc.time_limit > qos[job_desc.qos]['duration'] then
      log_error("slurm_job_submit: job time limit (%u) is longer than the QoS %s limit (%u)",
         job_desc.time_limit, job_desc.qos, qos[job_desc.qos]['duration'])
      return slurm.ESLURM_INVALID_TIME_LIMIT
   end

   slurm.log_info("slurm_job_submit: job from user:%s/%u account:%s minutes:%u cores:%u-%u nodes:%u-%u shared:%u partition:%s QOS:%s",
      job_desc.user_name,
      submit_uid,
      tostring(job_desc.account),
      job_desc.time_limit,
      job_desc.min_cpus,
      job_desc.max_cpus,
      job_desc.min_nodes,
      job_desc.max_nodes,
      job_desc.shared,
      tostring(job_desc.partition),
      tostring(job_desc.qos))

   return slurm.SUCCESS
end

--========================================================================--

function slurm_job_modify ( job_desc, job_rec, part_list, modify_uid )
   return slurm.SUCCESS
end

slurm.log_info("initialized")

return slurm.SUCCESS
