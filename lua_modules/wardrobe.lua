local wd = {}

--[[
    void SetOverrideMaterialItem(int slot, uint32 item);
    void ClearOverrideMaterialItems();

	local picked   = eq.get_data(lastpKey)
	local current  = "character-" .. cid .. ":iq-current";
	eq.set_data(current, picked, "1h");

 Lua_Inventory GetInventory();
]]--


wd.key = function(cid)
	return "wdrobe-" .. tostring(cid)
end

wd.get_settings = function(cid, client)
	local data = eq.get_data(wd.key(cid)) or ""
	local ret = {}
	if data == "" then return ret end
	return table.decode(data)
end

wd.set_settings = function(cid,tab)
	eq.set_data(wd.key(cid), table.encode(tab))
end

wd.save_show = function(cid, name)
	eq.set_data(wd.key(cid).."show",name)
end

wd.apply_show = function(client)
	local cid  = client:CharacterID()
	local name = eq.get_data(wd.key(cid).."show")

	if name then
		client:Message(10, "wdrobe - showing saved `" .. name .. "`")
		wd.show(client, name)
	end
end

wd.list = function(client)
	local cid  = client:CharacterID()
	local data = wd.get_settings(cid)
	local sets = data['set'] or {}

	local sorted = {}
	for n in pairs(sets) do table.insert(sorted, n) end
	table.sort(sorted)

	for i, v in ipairs(sorted) do
		client:Message(15, v)
	end
end

wd.remove = function(client, name)
	local cid  = client:CharacterID()
	local data = wd.get_settings(cid)
	local sets = data['set']

	if sets[name] then
		table.remove(sets, name)
	end

	wd.set_settings(cid, data)
	client:Message(10, "Removed: " .. name)
end

wd.save = function(client, name)
	local cid  = client:CharacterID()
	local data = wd.get_settings(cid,client)

	data['set'] = data['set'] or {}

	local sets = data['set']

	sets[name] = {}

	local save = sets[name]

	local inven = client:GetInventory()

	local slot = Slot.EquipmentBegin
	for slot=Slot.EquipmentBegin,Slot.EquipmentEnd do
		local mat = inven:CalcMaterialFromSlot(slot)
		if inven:HasItem(slot) and mat ~= 255 then
			local item = inven:GetItem(slot)
			if item:GetID() ~= 0 then
				-- client:Message(10, "saving " .. tostring(slot) .. " to mat: " .. tostring(mat) .. " itemid: " .. tostring(item:GetID()))
				save[mat] = item:GetID()
			end
		end
	end

	wd.set_settings(cid, data)
end

wd.show = function(client, name)
	local cid  = client:CharacterID()
	local data = wd.get_settings(cid)
	local sets = data['set'] or {}
	local saved = sets[name]

	if saved then
		for slot, mat in pairs(saved) do
			-- client:Message(10, "showing slot " .. tostring(slot) .. " item " .. tostring(mat))
    			client:SetOverrideMaterialItem(slot, mat)
		end

		wd.save_show(cid, name)
	else
		client:Message(10, "wdrobe: no set found for " .. name)
	end
end

wd.hide = function(client)
    client:ClearOverrideMaterialItems();
end

return wd
