local function help(c,o,miss)
	c:Message(10, "#wdrobe " .. o)
	c:Message(10,  " missing <" .. miss .. ">")
end

local function route(e)
	local client = e.self

	local option = ""
	local name   = ""

	if #e.args > 0 then
		option = e.args[1]
	end

	if #e.args > 1 then
		name = e.args[2]
	end

	if option == "show" then
		if name and name:len() > 3 then
			eq.wd.show(client, name)
		else
			eq.wd.apply_show(client)
		end
	elseif option == "save" then
		if name and name:len() > 3 then
			eq.wd.save(client, name)
		else
			help(client,option,"name")
		end
	elseif option == "remove" then
		if name and name:len() > 3 then
			eq.wd.remove(client, name)
		else
			help(client,option,"name")
		end
	elseif option == "list" then
		eq.wd.list(client)
	elseif option == "hide" then
		eq.wd.hide(client)
	else
		client:Message(10, "#wdrobe show <name>")
		client:Message(10, "#wdrobe save <name>")
		client:Message(10, "#wdrobe remove <name>")
		client:Message(10, "#wdrobe list")
		client:Message(10, "#wdrobe hide")
	end

	return true
end

return route

