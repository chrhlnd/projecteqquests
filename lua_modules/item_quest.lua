local iq = {}

iq.split = function(str, sep)
	local array = {}
	local reg = string.format("([^%s]+)", sep)
	for mem in string.gmatch(str, reg) do
		array[#array+1] = mem
	end
	return array
end

-- iid:<num>|npc:<num>|pctd:<f>|pcts:<f>|ar:<num>|nme:<name>|s2:<spawn2id>|sg:<spawng>|x:<float>|y:<float>|z:<float>|h:<float>|zn:<string>|zid:<num>
iq.unpack = function(str)
	local ret = {}
	-- eq.debug("Trying to parse - " .. str)
	for ele in string.gmatch(str, "([^|]+)") do
		local kv = iq.split(ele, ":")
		ret[#ret+1] = {kv[1],kv[2]}
		ret[kv[1]] = kv[2]
	end
	return ret
end

iq.unpack_target = function (thing)
	local parts = iq.split(thing, ":")

	local ret = {}
	ret.mobs = {}

	for i, v in ipairs(parts) do
		if i == 1 then
			ret.zone = v
		elseif i == 2 then
			ret.zoneName = parts[2]
		else
			table.insert(ret.mobs,tonumber(v))
		end
	end
	return ret
end

iq.pack_target = function (thing)
	local ret = ""

	ret = ret .. thing.zone or ""
	ret = ret .. ":"
	ret = ret .. thing.zoneName or ""
	
	for i,v in ipairs(thing.mobs) do
		ret = ret .. ":"
		ret = ret .. v
	end

	return ret
end

iq.last_picked = function(cid)
	local lastpKey = "character-" .. cid .. ":iq-last-p"
	local picked = eq.get_data(lastpKey)
	return iq.unpack(picked);
end

iq.get_current = function(cid)
	local current  = "character-" .. cid .. ":iq-current";
	local picked = eq.get_data(current)
	return iq.unpack(picked)
end

iq.set_current = function(cid)
	local lastpKey = "character-" .. cid .. ":iq-last-p"
	local picked   = eq.get_data(lastpKey)
	local current  = "character-" .. cid .. ":iq-current";
	eq.set_data(current, picked, "1h");
end

iq.clear_current = function(cid)
	local current  = "character-" .. cid .. ":iq-current";
	eq.delete_data(current)
end

iq.last_targets = function(cid,client)
	local d = eq.get_data(string.format("iq-target-%d", cid))
	if d ~= nil and string.len(d) > 0 then
		if client then
			client:Message(10, "here z")
		end
		return iq.unpack_target(d)
	end
	return nil
end

iq.last_targets_clear = function(cid)
	return eq.delete_data(string.format("iq-target-%d", cid))
end

iq.clear_all = function(cid)
	local lastqKey = "character-" .. cid .. ":iq-last-q"
	local lastpKey = "character-" .. cid .. ":iq-last-p"

	eq.delete_data(lastpKey)
	eq.delete_data(lastqKey)
	iq.last_targets_clear(cid)
	iq.clear_current(cid)
end

iq.check_all_targets_dead = function(cid, client)
	local ret = true
	local target = iq.last_targets(cid)
	if target ~= nil then
		for k,mobid in pairs(target.mobs) do
			if iq.isTargetMob(mobid,client) then
				ret = false
			end
		end
	end
	return ret
end

iq.end_if_all_targets_dead = function(cid,client)
	if iq.check_all_targets_dead(cid, client) then
		iq.clear_all(cid)
		client:Message(15, "[ItemQuest] all targets dead")
		return true
	end
	return false
end

iq.check_clear_target_dead = function(cid, mob, client)
	local target = iq.last_targets(cid)
	if target ~= nil then
		local npc = mob:CastToNPC()
		local npcid = mob:GetEntityVariable("wasMobId")
		for k,mobid in pairs(target.mobs) do
			-- eq.debug("Mob: " .. tostring(mobid) .. " ==? " .. tostring(npcid))
			if tonumber(mobid) == tonumber(npcid) then
				iq.clear_all(cid)
				client:Message(15, string.format("[ItemQuest] %s => KILLED", mob:GetCleanName()))
				break
			end
		end
	end
end

iq.has_last_targets = function(cid,client)
	local detail = eq.get_data(string.format("iq-target-%d", cid))
	return detail and detail.mobs
end

iq.set_last_targets = function(cid, mobids, zone, zoneName)
	local data = {}
	data.mobs = mobids
	data.zone = zone
	data.zoneName = zoneName

	eq.set_data(string.format("iq-target-%d", cid), iq.pack_target(data))
end

-- iid:<num>|npc:<num>|pctd:<f>|pcts:<f>|ar:<num>|nme:<name>|s2:<spawn2id>|sg:<spawng>|x:<float>|y:<float>|z:<float>|h:<float>|zn:<string>|zid:<num>
iq.report_cached = function(cid, client)
	local detail = iq.get_current(cid)
	if detail.zn ~= nil then
		client:Message(15, string.format("[%s] %s is still waiting to be killed.", detail.zn or "", detail.nme or ""))
	else
		client:Message(15, string.format("No item quest at this time."))
	end
end

iq.report = function(cid, client)
	local last = iq.last_targets(cid)
	local ret = false

	--if client then
	--	client:Message(10, "reporting  " .. table.encode(last))
	--end	

	if last ~= nil then
		local list =  eq.get_entity_list()
		for k,mobid in pairs(last.mobs) do
			-- if client then
			-- 	client:Message(10, "checking mob id: " .. tostring(mobid))
			-- end	
			if iq.isTargetMob(mobid,client) then
				local m = list:GetNPCByID(mobid)
    				client:Message(15, string.format("[%s] %s is still waiting to be killed.", last.zoneName, m:GetCleanName()))
				ret = true
			end
		end
	end
	return ret
end

iq.isTargetMob = function(mobid,client)
	local list = eq.get_entity_list()
	local o    = list:GetNPCByID(mobid)
	if o then
		local iqt = o:GetEntityVariable("iqt")
		if tostring(iqt) == tostring(mobid) then
			-- if client then
			-- 	client:Message(10, "Checking mob id " .. tostring(mobid) .. " for iqt var: " .. tostring(iqt))
			-- end
			return true
		end
	end
	return false
end

iq.tagTargetMob = function(mobid,client)
	--if client then
	--	client:Message(10, "in tag here")
	--end
	local list = eq.get_entity_list()
	local o    = list:GetNPCByID(mobid)
	if client then
		-- client:Message(10, "here 2")
		-- client:Message(10, "Trying to tag taget " .. tostring(mobid) .. " obj is " .. tostring(o))
	end
	if o then
		local val = tostring(mobid)
		-- if client then
			-- client:Message(10, "Set iqt var to " .. val)
		-- end
		o:SetEntityVariable("iqt", val)
		-- if client then
		-- 	client:Message(10, "here 3")
		-- end
		return true
	end
	-- client:Message(10, "nope")
	return false
end

iq.isspawned = function(cid,client)
	local last = iq.last_targets(cid)

	if last ~= nil then
		local list =  eq.get_entity_list()
		-- if client then
		-- 	client:Message(15, "Here")
		--end
		for k,mobid in pairs(last.mobs) do
			if iq.isTargetMob(mobid,client) then
				return true
			end
		end
	end
	return false
end

iq.depop_last = function(cid)
	local last = iq.last_targets(cid)

	if last ~= nil then
		local list =  eq.get_entity_list()
		for k,mobid in pairs(last.mobs) do
			if iq.isTargetMob(mobid) then
				local m = list:GetNPCByID(mobid)
				if m ~= nil then
					m:Despawn()
				end
			end
		end
	end

	iq.last_targets_clear(cid)
end

local function randomPos(target, x, y, z, h, range)
	range = range * 2
	local min = range * .4
	local nX = x
	local nY = y
	local nZ = z
	for i=1,1000 do
		local rx = (min+math.random(range*.6))
		local ry = (min+math.random(range*.6))

		nX = x + rx - (range * .5)
		nY = y + ry - (range * .5)
		nZ = target:FindGroundZ(nX, nY) + 1

		if target:CheckLoSToLoc(nX,nY,nZ) then
			-- eq.debug("Moved to " .. nX .. " Y: " .. nY .. " Z " .. nZ)
			-- eq.debug("Moved to: Was " .. x .. " Y: " .. y .. " Z " .. z)
			target:GMMove(nX, nY, nZ, h)
			break
		end
	end
end

iq.check_zone_spawn = function(detail, client)
	local thiszoneid = eq.get_zone_id()

	if not thiszoneid or not detail or not detail.zid then
		client:Message(15, string.format("invalid zone data"))
		return
	end	

	if tonumber(thiszoneid) == tonumber(detail.zid) then
		local dropP  = detail.pctd
		local spawnP = detail.pcts

		iq.depop_last(client:AccountID())

		local scale  = 3 * ((100 - (dropP * spawnP))/100)
		local dscale = 5 * ((100 - (dropP * spawnP))/100)
 
		local x   = tonumber(detail.x)
		local y   = tonumber(detail.y)
		local z   = tonumber(detail.z)
		local h   = tonumber(detail.h)
		local s2  = tonumber(detail.s2)
		local iid = tonumber(detail.iid)
		local npc = tonumber(detail.npc)

		local target = eq.spawn2d(npc, 0, 0, detail.x, detail.y, detail.z, detail.h) 
		local z = target:FindGroundZ(x, y) + 1
		target:GMMove(x, y, z, h)

		local aggrorange = tonumber(detail.ar)

		randomPos(target, x, y, z, h, aggrorange)

		for i = 1,3 do
			if math.random(1,5) <= 2 then
				local t1 = eq.spawn2d(npc, 0, 0, detail.x, detail.y, detail.z, detail.h) 
				local z = t1:FindGroundZ(x, y) + 1
				x = target:GetX()
				y = target:GetY()
				z = target:GetZ()

				t1:GMMove(x, y, z, h)
				t1:ChangeSize(t1:GetSize() * .666)
				randomPos(t1, x, y, z, h, aggrorange * 1.5)
				local n1 = t1:CastToNPC()
				n1:ModifyNPCStat("dmg_mul", tostring(dscale))
				n1:ClearItemList()
			end
		end

		local id = target:GetID();
		-- client:Message(10, "Tagging mob [" .. tostring(id) .. "]")
		iq.tagTargetMob(id,client);
		iq.set_last_targets(client:CharacterID(), {[1] = id}, thiszoneid, detail.zn);

		local npc = target:CastToNPC()
		if npc ~= nil then
			local hps = npc:GetMaxHP() + npc:GetMaxHP() * scale
			npc:ModifyNPCStat("max_hp" , tostring(hps))
			npc:ModifyNPCStat("dmg_mul", tostring(dscale))
			target:SetHP(hps)
			npc:AddItem(iid,1)
		end
	end
end


return iq;
