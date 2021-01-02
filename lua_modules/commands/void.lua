local function help(client)
	client:Message(15, "The Void - global trash bin that pays you!")
	client:Message(15, "-----")
	client:Message(15, "########   use the currency to redeem items on a special pot vendor in pok")
	client:Message(15, "#void show - see things in the void can customize with params, 15 items at a time are shown, per page. Use page::<x> to see the next page.")
	client:Message(15, "eg: #void show page::2 name::ruby")
	client:Message(15, "######")
	client:Message(15, "#void put")
	client:Message(15, "-(holding) item      - put it in the void and get a payout")
	client:Message(15, "-(holding) container - put the items in the container in the void and get payouts")
	client:Message(15, "#####")
end

local function grantVoidCurrency(client, itemid, amount)
	local count = eq.void_count(itemid)
	local amt = 500 - count
	if amt < 50 then
		amt = 50
	end
	amt = amt * amount
	eq.void_add(itemid, amount)
	client:AddAlternateCurrencyValue(29, amt)
	return { success = true, amount = amt }
end

local function voidPull(client, itemnum)
	local e = eq.void_count(itemnum)

	if client:GetAlternateCurrencyValue(29) >= 1000 and e > 0 then
		eq.void_add(itemnum, -1)
		client:AddAlternateCurrencyValue(29, -1000)
		client:SummonItem(itemnum)
	else
		if e < 1 then
			client:Message(MT.Unused1, "[The Void] lacks the item.")
		else
			client:Message(MT.Unused1, "[The Void] you lack the funds.")
		end
	end
end

local function split(str, sep)
	local array = {}
	local reg = string.format("([^%s]+)", sep)
	for mem in string.gmatch(str, reg) do
		array[#array+1] = mem
	end
	return array
end

local function route(e)

	local cid = e.self:CharacterID()

	local option = ""

	if #e.args > 0 then
		option = e.args[1]
	end

	if option == "show" then
		local p = {}

		for i = 2, #e.args do
			local parts = split(e.args[i], ":")
			if parts[1] == "page" then
				p.page = tonumber(parts[2]) - 1
			elseif parts[1] == "name" then
				p.name = parts[2]
			end
		end

		local res = eq.void_query(p)
		for i, v in ipairs(res) do
			e.self:Message(MT.Unused1, string.format("[The Void] [%s] (cost 1k) - %s - Qty %d", eq.say_link("#void pull " .. v.id,false,"pull"), eq.item_link(v.id), v.count))
		end

		local nxt = ""
		if #res > 14 then
			local n = "#void show page::" .. (p.page or 0)+2
			if p.name ~= nil then
				n = n .. " name::" .. e.name
			end
			nxt = eq.say_link(n, false, "next")
			eq.debug(n)
		end
		local prv = ""
		if p.page ~= nil and p.page > 0 then
			local n = "#void show page::" .. p.page
			if p.name ~= nil then
				n = n .. " name::" .. e.name
			end
			prv = eq.say_link(n, false, "prev")
		end
		if prv ~= "" or nxt ~= "" then
			e.self:Message(MT.Unused1, string.format("[The Void] %s ... %s", prv, nxt))
		end
		return
	end

	if option == "pull" then
		voidPull(e.self, tonumber(e.args[2]))
		return
	end

	if option == "put" then
		local ii = e.self:GetInventory():GetItem(Slot.Cursor)
		if ii ~= nil then
			local item = ii:GetItem()
			if item:ID() ~= 0 then
				e.self:Message(MT.Unused1, "Saw item " .. item:ID() .. " bag: " .. tostring(item:BagSlots()))
				if item:BagSlots() > 0 then
					for bslot = 0, item:BagSlots() do
						local bii   = e.self:GetInventory():GetItem(Slot.Cursor, bslot)
						local bitem = bii:GetItem()
						if bii ~= nil and bitem:ID() > 0 then
							if not bii:IsAugmented() then
								local res = grantVoidCurrency(e.self, bitem:ID(), bii:GetCharges())
								if res.success then
									e.self:NukeItem(bitem:ID(), 32)
									e.self:Message(MT.Unused1, string.format("[The Void] Took %s - %d and gave %d Shadowstone", bitem:Name(), bii:GetCharges(), res.amount))
								end
							else
								e.self:Message(MT.Unused1, string.format("Ignoring `%s` remove augment first.", bitem:Name()))
							end
						end
					end
				else
					local res = grantVoidCurrency(e.self, item:ID(), 1)
					if res.success then
						e.self:NukeItem(item:ID(), 32)
						e.self:Message(MT.Unused1, string.format("[The Void] Took %s - 1 and gave %d Shadowstone", item:Name(), res.amount))
					end
				end
			else
				e.self:Message(MT.Unused1, "Need to pickup an item")
			end
		else
			e.self:Message(MT.Unused1, "Need to pickup an item")
		end
		return
	end

	help(e.self)
end

return route
