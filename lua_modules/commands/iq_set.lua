local function iq_set(e)
	local cid = e.self:CharacterID()

	if e.command == "iq-clear" then
		eq.iq.clear_all(cid)
    	e.self:Message(15, string.format("Item Quest state cleared"))
		return true
	end

	if e.command == "iq-status" then
		eq.iq.report_cached(cid, e.self)
		return true
	end

	if eq.iq.isspawned(cid) then
		eq.iq.report(cid, e.self)
		return
	end

	local detail = eq.iq.last_picked(cid)

	eq.iq.set_current(cid)

    e.self:Message(15, string.format("%s has been targeted in %s", detail.nme, detail.zn));

	eq.iq.check_zone_spawn(detail, e.self)
end

return iq_set;
