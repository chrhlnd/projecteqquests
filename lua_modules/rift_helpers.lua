local slot_item = {
	[10] = { 52431, 52430 },
	 [9] = { 52430, 52431 },
	[17] = { 52432 },
	[20] = { 52422 },
}

local export = {}

local function dohit(c,ec)
	local maxHp = c:GetMaxHP()
	local hp = c:GetHP()

	hit = math.ceil(maxHp / ec)
	if hit > hp then
		hit = math.ceil(hp / 2)
	end
	c:Damage(c, hit, 0, 0)
	c:Message(MT.Skills, ">> You take " .. hit .. " for your flagulation")
end

local function checkTimerTrap()
	if eq.add_player_trap_timer == nil then
		eq.add_player_trap_timer = function(fn)
			local traps = {}
			if eq.player_trap_timers ~= nil then
				traps = eq.player_trap_timers
			end
			table.insert(traps, fn)
			eq.player_trap_timers = traps
		end
	end

	if eq.rem_player_trap_timer == nil then
		eq.rem_player_trap_timer = function (idx)
			local traps = {}
			if eq.player_trap_timers ~= nil then
				traps = eq.player_trap_timers
			end
			table.remove(traps, idx)
			eq.player_trap_timers = traps
		end
	end
end

local _enslaveActive = 0

local function enslave(e)
	local c = e.owner:CastToClient()
	local ec = export.countEquipped(c)

	local pet = c:GetPet()
	if (pet ~= nil and pet:GetName() ~= "" ) or _enslaveActive == 1 then
		c:Message(MT.Skills, ">> can't ENSLAVE already have a pet - " .. pet:GetName())
		return
	end

	local t = c:GetTarget()
	if t == nil then
		return
	end

	local tid = t:GetID()

	checkTimerTrap()

	local function findTarget()
		eq.debug("Trying to find target " .. tostring(tid))
		local list = eq.get_entity_list()
		return list:GetNPCByID(tid)
	end

	local timer_trap = function(idx, e)
		if e.timer == "enslave" then
			ec = ec - 1

			t = findTarget()
			if t ~= nil then
				t:BuffFadeBySpellID(6144)
				c:SpellFinished(6144, t); -- charm
				c:Message(MT.Skills, ">> ENSLAVING " .. t:GetName() .. "  have " .. ec .. " refreshes left")
			else
				c:Message(MT.Skills, ">> ENSLAVING failed to find target")
			end
			if ec <= 0 or t == nil then
				_enslaveActive = 0
    			eq.stop_timer(e.timer)
				eq.rem_player_trap_timer(idx)
			end
		end
	end

	eq.add_player_trap_timer(timer_trap)

    eq.set_timer("enslave", (6 * 8) * 1000, c);
	t = findTarget()
	t:BuffFadeBySpellID(6144)
	c:SpellFinished(6144, t); -- charm
	c:Message(MT.Skills, ">> ENSLAVING " .. t:GetName() .. " you have " .. ec .. " refreshes left")
	dohit(c,ec)
end


local function timehaste(e)
	local c = e.owner:CastToClient()
	local ec = export.countEquipped(c)

	checkTimerTrap()

	local timer_trap = function(idx, e)
		if e.timer == "timehaste" then
			ec = ec - 1
			c:SpellFinished(6405, c); --Academics Intelect
			c:SpellFinished(911, c); --Whoop ass
			c:Message(MT.Skills, ">> HASTING have " .. ec .. " refreshes left")
			if ec <= 0 then
    			eq.stop_timer(e.timer)
				eq.rem_player_trap_timer(idx)
			end
		end
	end

	eq.add_player_trap_timer(timer_trap)

    eq.set_timer("timehaste", (6 * 7) * 1000, c);
	c:SpellFinished(6405, c); --Academics Intelect
	c:SpellFinished(911, c); --Whoop ass
	c:Message(MT.Skills, ">> HASTING you have " .. ec .. " refreshes left")
	dohit(c,ec)
end

local function cleanse(e)
	local c = e.owner:CastToClient()

	local ec = export.countEquipped(c)


	local cleared = false
	local buffs = c:BuffSpellIds()
	for _,spell in pairs(buffs) do
		local s = Spell(spell)
		if s:GoodEffect() == 0 then
			cleared = true
			c:BuffFadeBySpellID(spell)
			local dur = 15 * ec
			c:AddSpellImmune(spell, dur, dur)
			c:Message(MT.Skills, ">> Fading " .. s:Name() .. " gaining immume for " .. dur .. "sec")
		end
	end

	if cleared then
		dohit(c,ec)
	end
end

local function stop_it(e)
	local c = e.owner:CastToClient()
	local ec = export.countEquipped(c)

	if ec > 3 then
		c:SpellFinished(10601,c) -- symph aura
	end
	if ec > 2 then
		c:SpellFinished(8506,c) -- ward of bedazelment
	end
	if ec > 1 then
		c:SpellFinished(10649,c:GetTarget()) -- ae mez memblur
	end
	if ec > 0 then
		c:SpellFinished(10631,c:GetTarget()) -- ae mez memblur
		c:SpellFinished(12576,c:GetTarget()) -- ae mez memblur
	end

	c:Message(MT.Skills, ">> Time out!")
	dohit(c,ec)
end

local effect = {
	[52431] = cleanse,
	[52430] = stop_it,
	[52432] = timehaste,
	[52422] = enslave,
}

export.countEquipped = function (client)
	local ret = 0

	for slot, items in pairs(slot_item) do
		for _, itemid in pairs(items) do
			if client:GetItemIDAt(slot) == itemid then
				ret = ret + 1
			end
		end
	end

	return ret
end

export.item_click = function (e)
	-- e.self == item
	-- e.slot_id == slot
	-- e.owner == char
	if e.owner:IsClient() then
		local id = e.self:GetID()

		if effect[id] ~= nil then
			effect[id](e)
		end

	end
end


return export
