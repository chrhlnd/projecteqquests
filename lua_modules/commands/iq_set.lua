local function iq_set(e)
	local cid = e.self:CharacterID()

	if e.command == "iq-clear" then
		eq.iq.clear_all(cid)
	    	e.self:Message(15, string.format("Item Quest state cleared"))
		return true
	end

	if e.command == "iq-status" then
		if not eq.iq.end_if_all_targets_dead(cid,e.self) then
			eq.iq.report(cid, e.self) 
		end
		return true
	end

	if eq.iq.isspawned(cid, e.self) then
		eq.iq.report(cid, e.self)
		return true
	end

	local detail = eq.iq.last_picked(cid)
	
	-- e.self:Message(10, string.format("Detail %s", table.encode(detail)))

	-- e.self:Message(15, "SETTING CURRENT")
	eq.iq.set_current(cid)
	-- e.self:Message(15, "check spawn")
	eq.iq.check_zone_spawn(detail, e.self)

	detail = eq.iq.get_current(cid)

	e.self:Message(15, string.format("%s has been targeted in %s", detail.nme, detail.zn));
	return true
end

return iq_set;
