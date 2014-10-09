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

QOS_SEP = "|"		-- separator for sacctmgr command ouput
QOS_NAME_SEP = "_"	-- separator for QOS name
NULL = 4294967294	-- numeric nil
CORE_PER_CPU=24

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
	-- set	: table where the element is to be added
	-- key	: element to be added
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
	-- inputstr	: string to be split
	-- sep 		: separator for split the string
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
	-- cmd	: command to be executed
	local f = assert(io.popen(cmd, 'r'))
	local s = assert(f:read('*a'))
	f:close()
	s = string.gsub(s, '^%s+', '')
	s = string.gsub(s, '%s+$', '')
	s = string.gsub(s, '[\n\r]+', ' ')
	return s
end

--========================================================================--

function _build_part_table(part_list)
	-- Create a partition table from SLURM structure
	local part_rec = {}

	for i in ipairs(part_list) do
		part_rec[i] = { part_rec_ptr=part_list[i] }
		setmetatable (part_rec[i], part_rec_meta)
	end
	return part_rec
end

--========================================================================--

function default_partition(part_rec)
	-- Return the name of the default partition
	-- part_rec	: list of partitions
	local i = 1

	while part_rec[i] do
		if part_rec[i].flag_default == 1 then
			return part_rec[i].name
		end
		i = i + 1
	end
end

--========================================================================--

function default_time(part_rec, partition)
	-- Return the default duration for the partition
	-- part_rec : list of partitions
	-- partition : name of the partition
	local i = 1

	while part_rec[i] do
		if part_rec[i].name == partition then
			return part_rec[i].default_time
		end
		i = i + 1
	end
end

--========================================================================--

function to_minute(inputstr)
	-- convert SLURM time format in minute :
	-- inpustr : string should looks like :
	--	minutes, minutes:seconds, hours:minutes:seconds,
	--	days-hours, days-hours:minutes, days-hours:minutes:seconds
	local d,h,m,s
	local t

	if inputstr ~= nil then
		-- Test if a day is indicated (string separated by "-"
		d,t = string.match (inputstr, "^(%d*)-(.*)$")

		if d == nil then -- no day indicated
			m = string.match (inputstr, "^(%d*)$")
			if m ~= nil then  -- minutes indicated
				return m
			else
				m, s = string.match (inputstr, "^(%d*):(%d*)$")
				if m ~= nil and  s ~= nil then -- minutes:seconds indicated
					-- seconds ceiled to one minute if greater than 1
					return m * 60 + math.ceil(s/60)
				else
					h,m,s = string.match (inputstr, "^(%d*):(%d*):(%d*)$")
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
				return j + m
			else
				h, m = string.match (t, "^(%d*):(%d*)$") -- hours:minutes indicated
				if h ~= nil and  m ~= nil then
					return d + h * 60 + m
				else
					h,m,s = string.match (t, "^(%d*):(%d*):(%d*)$") -- hours:minutes:seconds indicated
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
		-- table.sort(qos_list) -- sort qos (optional)
		for i, qos in ipairs(qos_list) do
			if qos_list[qos] ~= nil then
				-- table.sort(qos_list[qos]) --sort maxcpus
              			for j, maxcpus in ipairs(qos_list[qos]) do
					if qos_list[qos][maxcpus] ~= nil then
						-- table.sort(qos_list[qos][maxcpus], function(x,y) return tonumber(x) < tonumber(y) end) --sort duration
						table.sort(qos_list[qos][maxcpus]) --sort duration
					end
				end
			end
		end
	end
	io.close(qos_rec)
	return qos_list
end

--########################################################################--
--
--  SLURM job_submit/lua interface:
--
--########################################################################--

function slurm_job_submit ( job_desc, part_list )
	setmetatable (job_desc, job_req_meta)
	local part_rec = _build_part_table (part_list)
	local username
	local qos_list = build_qos_list()
	local maxtime
	local maxcpus
        local cmd =  "getent passwd " .. job_desc.user_id .. "| awk -F':' '{print tolower($1)}'"

        username = os.capture(cmd) -- convert uid to logname

	-- QOS set by user
	if job_desc.qos ~= nil  then

		local t = split(job_desc.qos, QOS_NAME_SEP)

		partition = t[1]
		size = t[2]
		duration = t[3]

		if job_desc.partition == nil then
			job_desc.partition = partition
		end
	else
		-- Time limit not set by user, set to partition default time limit
		if job_desc.time_limit == NULL then -- no time limit
			job_desc.time_limit = 60 -- 1 heure
		end

		-- CPU limit not set by user, set to default CPU limit
		if job_desc.min_cpus == nil then -- no cpu limit
			job_desc.min_cpus = 1
		end

		-- Define QOS

		-- Search maxcpus limit and time limit best combinaison
		if qos_list ~= nil then
			for h, u in pairs (qos_list) do -- research by partition
				if job_desc.partition == nil or job_desc.partition == u then
					maxcpus = ""

					if qos_list[u] ~= nil then
						for i, v in ipairs(qos_list[u]) do -- research best maxcpus
							if job_desc.min_cpus <= tonumber(v) and (job_desc.max_nodes == NULL or job_desc.max_nodes <= tonumber(v) / CORE_PER_CPU) then

								maxcpus = v
								maxtime=0
								if qos_list[u][maxcpus] ~= nil then
									for j, w in ipairs(qos_list[u][maxcpus]) do -- research best time
										if job_desc.time_limit <= tonumber(w) then
											maxtime = w
											break
										end
									end

									if maxtime ~= 0 then -- limit not yet found out
										-- Will give the best QOS
										job_desc.qos = qos_list[u][maxcpus][maxtime]
										job_desc.partition = u
										break
									end
								end
							end
						end
					end
				end
			end
		end

		--      If no default partition, set the partition to the highest
		--      priority partition this user has access to
	        if job_desc.partition == nil then
			for i in ipairs(part_rec) do
				if i == 1 then
					job_desc.partition = part_rec[i].name
					job_desc.qos = "normal"
					break
				end
			end
		end
	end

	log_info("slurm_job_modify: job from user:%s/%u minutes:%u cpus/nodes:%u partition:%s QOS:%s", username, job_desc.user_id, job_desc.time_limit, job_desc.min_cpus, showstring(job_desc.partition), showstring(job_desc.qos))

        return 0
end

--========================================================================--

function slurm_job_modify ( job_desc, job_rec, part_list )
	setmetatable (job_desc, job_req_meta)
	setmetatable (job_rec,  job_rec_meta)
	local part_rec = _build_part_table (part_list)

	return 0
end

--########################################################################--
--
--  Initialization code:
--
--  Define functions for logging and accessing slurmctld structures
--
--########################################################################--

log_info = slurm.log_info
log_verbose = slurm.log_verbose
log_debug = slurm.log_debug
log_err = slurm.error

job_rec_meta = {
	__index = function (table, key)
		return _get_job_rec_field(table.job_rec_ptr, key)
	end
}
job_req_meta = {
	__index = function (table, key)
		return _get_job_req_field(table.job_desc_ptr, key)
	end,
	__newindex = function (table, key, value)
		return _set_job_req_field(table.job_desc_ptr, key, value)
	end
}
part_rec_meta = {
	__index = function (table, key)
		return _get_part_rec_field(table.part_rec_ptr, key)
	end
}

log_info("initialized")

return slurm.SUCCESS
