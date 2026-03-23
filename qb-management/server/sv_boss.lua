local QBCore = exports['qb-core']:GetCoreObject()
local Accounts = {}

function ExploitBan(id, reason)
	MySQL.insert('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
		GetPlayerName(id),
		QBCore.Functions.GetIdentifier(id, 'license'),
		QBCore.Functions.GetIdentifier(id, 'discord'),
		QBCore.Functions.GetIdentifier(id, 'ip'),
		reason,
		2147483647,
		'qb-management'
	})
	TriggerEvent('l2s-log:server:CreateLog', 'bans', 'Player Banned', 'red', string.format('%s was banned by %s for %s', GetPlayerName(id), 'qb-management', reason), true)
	DropPlayer(id, 'You were permanently banned by the server for: Exploiting')
end

function GetAccount(account)
	return Accounts[account] or 0
end

function AddMoney(account, amount)
	if not Accounts[account] then
		Accounts[account] = 0
	end

	Accounts[account] = Accounts[account] + amount
	MySQL.insert('INSERT INTO management_funds (job_name, amount, type) VALUES (:job_name, :amount, :type) ON DUPLICATE KEY UPDATE amount = :amount',
		{
			['job_name'] = account,
			['amount'] = Accounts[account],
			['type'] = 'boss'
		})
end

function RemoveMoney(account, amount)
	local isRemoved = false
	if amount > 0 then
		if not Accounts[account] then
			Accounts[account] = 0
		end

		if Accounts[account] >= amount then
			Accounts[account] = Accounts[account] - amount
			isRemoved = true
		end

		MySQL.update('UPDATE management_funds SET amount = ? WHERE job_name = ? and type = "boss"', { Accounts[account], account })
	end
	return isRemoved
end

MySQL.ready(function ()
	local bossmenu = MySQL.query.await('SELECT job_name, amount FROM management_funds WHERE type = "boss"', {})
	if not bossmenu then return end

	for _,v in ipairs(bossmenu) do
		Accounts[v.job_name] = v.amount
	end
end)

RegisterNetEvent("l2s-bossmenu:server:withdrawMoney", function(amount)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)

	if not Player.PlayerData.job.isboss then  return end

	local job = Player.PlayerData.job.name
	if RemoveMoney(job, amount) then
		Player.Functions.AddMoney("cash", amount, 'Boss menu withdraw')
		TriggerEvent('l2s-log:server:CreateLog', 'bossmenu_moneysafe', 'BossMenu - Withdraw Money', "blue", Player.PlayerData.name.. "Withdrawal $" .. amount .. ' (' .. job .. ')', false)
		TriggerClientEvent('QBCore:Notify', src, "You have withdrawn: $" ..amount, "success")
	else
		TriggerClientEvent('QBCore:Notify', src, "You dont have enough money in the account!", "error")
	end

	TriggerClientEvent('l2s-bossmenu:client:OpenMenu', src)
end)

RegisterNetEvent("l2s-bossmenu:server:depositMoney", function(amount)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)

	if not Player.PlayerData.job.isboss then  return end

	if Player.Functions.RemoveMoney("cash", amount) then
		local job = Player.PlayerData.job.name
		AddMoney(job, amount)
		TriggerEvent('l2s-log:server:CreateLog', 'bossmenu_moneysafe', 'BossMenu - Deposit Money', "blue", Player.PlayerData.name.. "Deposit $" .. amount .. ' (' .. job .. ')', false)
		TriggerClientEvent('QBCore:Notify', src, "You have deposited: $" ..amount, "success")
	else
		TriggerClientEvent('QBCore:Notify', src, "You dont have enough money to add!", "error")
	end

	TriggerClientEvent('l2s-bossmenu:client:OpenMenu', src)
end)

RegisterNetEvent('l2s-bossmenu:server:OpenStash', function(job) 
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if not Player.PlayerData.job.isboss then  return end
	local data = { label = 'Boss Stash', maxweight = 3000000, slots = 100 }
    exports['l2s-inventory']:OpenInventory(src, 'Boss_'..job, data)
end)


QBCore.Functions.CreateCallback('l2s-bossmenu:server:GetAccount', function(_, cb, jobname)
	local result = GetAccount(jobname)
	cb(result)
end)

-- Get Employees
QBCore.Functions.CreateCallback('l2s-bossmenu:server:GetEmployees', function(source, cb, jobname)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player.PlayerData.job.isboss then return end

    local employees = {}
    local onlineCids = {}

    for _, pid in pairs(QBCore.Functions.GetPlayers()) do
        local ply = QBCore.Functions.GetPlayer(pid)
		print(1, ply.PlayerData.job.name)
		print(2,jobname)
        if ply and ply.PlayerData.job.name == jobname then
            employees[#employees+1] = {
                empSource = ply.PlayerData.citizenid,
                grade = ply.PlayerData.job.grade,
                isboss = ply.PlayerData.job.isboss,
                profile_image = ply.PlayerData.profile_image,
                name = '🟢 ' .. ply.PlayerData.charinfo.firstname .. ' ' .. ply.PlayerData.charinfo.lastname
            }
            onlineCids[ply.PlayerData.citizenid] = true
        end
    end

    local players = MySQL.query.await("SELECT * FROM `players` WHERE `job` LIKE '%".. jobname .."%'", {})
    if players and players[1] ~= nil then
        for _, value in pairs(players) do
            if not onlineCids[value.citizenid] then
                local jobData = json.decode(value.job)
                local charinfo = json.decode(value.charinfo)
                employees[#employees+1] = {
                    empSource = value.citizenid,
                    grade = jobData.grade,
                    isboss = jobData.isboss,
                    profile_image = value.profile_image,
                    name = '❌ ' .. charinfo.firstname .. ' ' .. charinfo.lastname
                }
            end
        end
    end

    -- Sort by grade level, highest first (for both online and offline)
    table.sort(employees, function(a, b)
        return a.grade.level > b.grade.level
    end)

    cb(employees)
end)

-- Bussiness Function

QBCore.Functions.CreateCallback('l2s-bossmenu:server:GetAllBussiness', function(source, cb)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	if not Player.PlayerData.job.isboss then  return end
    local result = MySQL.query.await('SELECT * FROM business')
	
	cb(result)
end)



RegisterNetEvent('l2s-bossmenu:server:EditBussinessPrice', function(data, newprice)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
	if not Player.PlayerData.job.isboss then  return end
    MySQL.update('UPDATE business SET price = ? WHERE business = ? ', {newprice, data.business})
    TriggerClientEvent('QBCore:Notify', src, 'Price updated to $'..newprice, 'success')
	TriggerEvent("l2s-log:server:CreateLog", "business_settings", "Manage Business - Edit Price", "green", "\n\n **Mayor :"..Player.PlayerData.charinfo.firstname.. " "..Player.PlayerData.charinfo.lastname.."\n\n Business: "..data.business.."\n\n Old Price : "..data.price.. "$\n\n New Price : "..newprice.."$**")
end)

RegisterNetEvent('l2s-bossmenu:server:EditBussinessLabel', function(data, newprice)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
	if not Player.PlayerData.job.isboss then  return end
    MySQL.update('UPDATE business SET label = ? WHERE business = ? ', {newprice, data.business})
    TriggerClientEvent('QBCore:Notify', src, 'Label updated to '..newprice, 'success')
	TriggerEvent("l2s-log:server:CreateLog", "business_settings", "Manage Business - Edit Label", "green", "\n\n **Mayor :"..Player.PlayerData.charinfo.firstname.. " "..Player.PlayerData.charinfo.lastname.."\n\n Business: "..data.business.."\n\n Old Label : "..data.label.. "\n\n New Label : "..newprice.."**")
end)

RegisterNetEvent('l2s-bossmenu:server:TransferOwnership', function(data, newowner)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player.PlayerData.job.isboss then return end


	if newowner == 'none' then
		if data.citizenid ~= 'none' then
			FiredJob(src, data.citizenid)
			MySQL.update('UPDATE business SET citizenid = ? WHERE business = ? ', {'none', data.business})
		else
			MySQL.update('UPDATE business SET citizenid = ? WHERE business = ? ', {'none', data.business})
		end
		TriggerEvent("l2s-log:server:CreateLog", "business_ownership", "Manage Business Ownership - Remove Owner", "green", "\n\n **Mayor :"..Player.PlayerData.charinfo.firstname.. " "..Player.PlayerData.charinfo.lastname.."\n\n Business: "..data.business.."\n\n Old Owner : "..data.citizenid.. "\n\n New Owner : none (Without Owner) **")
	else
		if data.citizenid == 'none' then
			if newowner == 'none' then
				TriggerClientEvent('QBCore:Notify', src, 'Business already has no owner.', 'success')
				return
			else
				AssignNewOwner(src, newowner, data)
			end
		else
			AssignNewOwner(src, newowner, data)
		end
	end

end)

function AssignNewOwner(src, newowner, data)
    local NewOwner = QBCore.Functions.GetPlayerByCitizenId(newowner)
    local Player = QBCore.Functions.GetPlayer(src)
    if NewOwner then
        if NewOwner.Functions.SetJob(data.job, data.grade) then
            TriggerClientEvent('QBCore:Notify', src, "Ownership transferred!", "success")
            TriggerClientEvent('QBCore:Notify', NewOwner.PlayerData.source, "You are now the owner of a new business! Good luck.", "success")
            MySQL.update('UPDATE business SET citizenid = ? WHERE business = ?', { newowner, data.business })
			TriggerEvent("l2s-log:server:CreateLog", "business_ownership", "Manage Business Ownership - Assign Owner", "green", "\n\n **Mayor :"..Player.PlayerData.charinfo.firstname.. " "..Player.PlayerData.charinfo.lastname.."\n\n Business: "..data.business.."\n\n Old Owner : "..data.citizenid.. "\n\n New Owner : "..newowner.." **")
        else
            TriggerClientEvent('QBCore:Notify', src, "Error transferring ownership.", "error")
        end
    else
        local player = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', { newowner })
        if player[1] then
            local jobData = {
                name = data.job,
                payment = QBCore.Shared.Jobs[data.job].grades[tostring(data.grade)].payment or 50,
                onduty = true,
                isboss = true,
                grade = {
                    name = nil,
                    level = data.grade
                }
            }
            MySQL.update('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(jobData), newowner })
			MySQL.update('UPDATE business SET citizenid = ? WHERE business = ?', { newowner, data.business })
			TriggerEvent("l2s-log:server:CreateLog", "business_ownership", "Manage Business Ownership - Assign Owner", "green", "\n\n **Mayor :"..Player.PlayerData.charinfo.firstname.. " "..Player.PlayerData.charinfo.lastname.."\n\n Business: "..data.business.."\n\n Old Owner : "..data.citizenid.. "\n\n New Owner : "..newowner.." **")
            TriggerClientEvent('QBCore:Notify', src, "Ownership transferred to an offline player!", "success")
			FiredJob(src, data.citizenid)
		else
            TriggerClientEvent('QBCore:Notify', src, "Player not found in the city.", "error")
        end
    end
end

function FiredJob(src, citizenid)
    local OldOwner = QBCore.Functions.GetPlayerByCitizenId(citizenid)

    if OldOwner then
        if OldOwner.Functions.SetJob("unemployed", '0') then
            TriggerClientEvent('QBCore:Notify', OldOwner.PlayerData.source, "You have been removed from your business by the mayor.", "success")
        else
            TriggerClientEvent('QBCore:Notify', src, "Error updating old owner's job.", "error")
        end
    else
        local player = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', { citizenid })
        if player[1] then
            local jobData = {
                name = 'unemployed',
                payment = QBCore.Shared.Jobs['unemployed'].grades['0'].payment or 50,
                onduty = true,
                isboss = false,
                grade = {
                    name = nil,
                    level = 0
                }
            }
            MySQL.update('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(jobData), citizenid })
        else
            TriggerClientEvent('QBCore:Notify', src, "Previous owner not found in the city.", "error")
        end
    end
end


-- Grade Change
RegisterNetEvent('l2s-bossmenu:server:GradeUpdate', function(data)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local Employee = QBCore.Functions.GetPlayerByCitizenId(data.cid)

	if not Player.PlayerData.job.isboss then  return end
	if data.grade > Player.PlayerData.job.grade.level then TriggerClientEvent('QBCore:Notify', src, "You cannot promote to this rank!", "error") return end
	
	if Employee then
		if Employee.Functions.SetJob(Player.PlayerData.job.name, data.grade) then
			TriggerEvent('l2s-log:server:CreateLog', 'bossmenu_jobs', 'BossMenu - Grade Update', "lightgreen", (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname).. " successfully Update Grade For: " .. (Employee.PlayerData.charinfo.firstname .. ' ' .. Employee.PlayerData.charinfo.lastname) .. 'New Grade: (' .. data.gradename .. ')', false)
			
			TriggerClientEvent('QBCore:Notify', src, "Sucessfulluy promoted!", "success")
			TriggerClientEvent('QBCore:Notify', Employee.PlayerData.source, "You have been promoted to" ..data.gradename..".", "success")
		else
			TriggerClientEvent('QBCore:Notify', src, "Promotion grade does not exist.", "error")
		end
	else
		TriggerClientEvent('QBCore:Notify', src, "Civilian not in city.", "error")
	end
	TriggerClientEvent('l2s-bossmenu:client:OpenMenu', src)
end)

-- Fire Employee
RegisterNetEvent('l2s-bossmenu:server:FireEmployee', function(target)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local Employee = QBCore.Functions.GetPlayerByCitizenId(target)

	if not Player.PlayerData.job.isboss then  return end

	if Employee then
		if target ~= Player.PlayerData.citizenid then
			if Employee.PlayerData.job.grade.level > Player.PlayerData.job.grade.level then TriggerClientEvent('QBCore:Notify', src, "You cannot fire this citizen!", "error") return end
			if Employee.Functions.SetJob("unemployed", '0') then
				TriggerEvent("l2s-log:server:CreateLog", "bossmenu_jobs", "BossMenu - Job Fire", "red", Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. ' successfully fired ' .. Employee.PlayerData.charinfo.firstname .. " " .. Employee.PlayerData.charinfo.lastname .. " (" .. Player.PlayerData.job.name .. ")", false)
				TriggerClientEvent('QBCore:Notify', src, "Employee fired!", "success")
				TriggerClientEvent('QBCore:Notify', Employee.PlayerData.source , "You have been fired! Good luck.", "error")
			else
				TriggerClientEvent('QBCore:Notify', src, "Error..", "error")
			end
		else
			TriggerClientEvent('QBCore:Notify', src, "You can\'t fire yourself", "error")
		end
	else
		local player = MySQL.query.await('SELECT * FROM players WHERE citizenid = ? LIMIT 1', { target })
		if player[1] ~= nil then
			Employee = player[1]
			Employee.job = json.decode(Employee.job)
			if Employee.job.grade.level > Player.PlayerData.job.grade.level then TriggerClientEvent('QBCore:Notify', src, "You cannot fire this citizen!", "error") return end
			local job = {}
			job.name = 'unemployed'
			job.payment = QBCore.Shared.Jobs[job.name]['grades']['0'].payment
			job.payment = QBCore.Shared.Jobs[job.name].grades['0'].payment or 500
			job.onduty = true
			job.isboss = false
			job.grade = {}
			job.grade.name = nil
			job.grade.level = 0
			MySQL.update('UPDATE players SET job = ? WHERE citizenid = ?', { json.encode(job), target })
			TriggerClientEvent('QBCore:Notify', src, "Employee fired!", "success")
			TriggerEvent("l2s-log:server:CreateLog", "bossmenu_jobs", "BossMenu - Job Fire", "red", Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname .. ' successfully fired ' .. Employee.PlayerData.charinfo.firstname .. " " .. Employee.PlayerData.charinfo.lastname .. " (" .. Player.PlayerData.job.name .. ")", false)
		else
			TriggerClientEvent('QBCore:Notify', src, "Civilian not in city.", "error")
		end
	end
	TriggerClientEvent('l2s-bossmenu:client:OpenMenu', src)
end)


-- Recruit Player
RegisterNetEvent('l2s-bossmenu:server:HireEmployee', function(recruit)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local Target = QBCore.Functions.GetPlayer(recruit)

	if not Player.PlayerData.job.isboss then  return end

	if Target and Target.Functions.SetJob(Player.PlayerData.job.name, 0) then
		TriggerClientEvent('QBCore:Notify', src, "You hired " .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. " come " .. Player.PlayerData.job.label .. "", "success")
		TriggerClientEvent('QBCore:Notify', Target.PlayerData.source , "You were hired as " .. Player.PlayerData.job.label .. "", "success")
		TriggerEvent('l2s-log:server:CreateLog', 'bossmenu_jobs', 'BossMenu - Recruit', "lightgreen", (Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname).. " successfully recruited " .. (Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname) .. ' (' .. Player.PlayerData.job.name .. ')', false)
	end
	TriggerClientEvent('l2s-bossmenu:client:OpenMenu', src)
end)

-- Get closest player sv
QBCore.Functions.CreateCallback('l2s-bossmenu:getplayers', function(source, cb)
	local src = source
	local players = {}
	local PlayerPed = GetPlayerPed(src)
	local pCoords = GetEntityCoords(PlayerPed)
	for _, v in pairs(QBCore.Functions.GetPlayers()) do
		local targetped = GetPlayerPed(v)
		local tCoords = GetEntityCoords(targetped)
		local dist = #(pCoords - tCoords)
		if PlayerPed ~= targetped and dist < 10 then
			local ped = QBCore.Functions.GetPlayer(v)
			players[#players+1] = {
			id = v,
			coords = GetEntityCoords(targetped),
			name = ped.PlayerData.charinfo.firstname .. " " .. ped.PlayerData.charinfo.lastname,
			citizenid = ped.PlayerData.citizenid,
			sources = GetPlayerPed(ped.PlayerData.source),
			sourceplayer = ped.PlayerData.source
			}
		end
	end
		table.sort(players, function(a, b)
			return a.name < b.name
		end)
	cb(players)
end)
