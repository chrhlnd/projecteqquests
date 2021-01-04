--copy or symbolic link this file to /server/lua_modules/, it will not work in /server/quests/lua_modules/

local commands_path = "lua_modules/commands/";
local commands      = { };

require('lua_modules/tab_serialize')

local function last_zone(e)
	eq.debug("yo")
	local last = e.self:GetEntityVariable("lastZone")
	eq.debug("Last Zone from var: " .. (last or "nope"))
end

commands["endurance"]   = { 50,  require(commands_path .. "endurance") };
commands["lockouts"]    = { 0,   require(commands_path .. "lockouts") };
commands["findnpcs"]    = { 200, require(commands_path .. "find_npcs") };
commands["timeleft"]    = { 0,   require(commands_path .. "time_left") };
commands["iqpickapply"] = { 0,   require(commands_path .. "iq_set") };
commands["iq-clear"]    = { 10,  require(commands_path .. "iq_set") };
commands["iq-status"]   = { 0,   require(commands_path .. "iq_set") };
commands["iq-spawn"]    = { 0,   require(commands_path .. "iq_set") };
commands["last-zone"]   = { 0,   last_zone };
commands["info"]        = { 0,   require(commands_path .. "info") };
commands["void"]        = { 0,   require(commands_path .. "void") };
commands["wdrobe"]      = { 0,   require(commands_path .. "wdrobe") };

function eq.DispatchCommands(e)
	-- eq.debug("[command.lua] got here in command - " .. (e.command or "unk"));
	local command = commands[e.command];

	for k,v in pairs(e.args) do
		eq.debug("[command.lua] key " .. k .. ' value ' .. v);
	end

	if(command) then
		local access = command[1];
		if(access > e.self:Admin()) then
			e.self:Message(13, "Access level not high enough.");
			return 1;
		end

		local func = command[2];
		func(e);
		return 1;
	end	
	return 0;
end
