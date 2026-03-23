
local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('l2s-justice:client:MayorMenu', function()
    local SocietyMenu = {
        {
            header = "Mayor Menu",
            isMenuHeader = true,
            icon = "fa-solid fa-laptop",
        },
        {
            header = "Manage Business",
            icon = "fa-solid fa-building",
            txt = "City Business Control",
            params = {
                event = "l2s-bossmenu:client:ShowAllBusiness",
            }
        },
        {
            header = "Review Cases",
            icon = "fa-solid fa-folder-open",
            txt = "City Business Control",
            params = {
                event = "l2s-cityhall:client:manage:cases:ongoing",
            }
        },
    }
    exports['l2s-ui']:openMenu(SocietyMenu)
end)

RegisterNetEvent('l2s-bossmenu:client:ShowAllBusiness', function()
    local businessMenu = {
        {
            header = "Mayor Menu",
            isMenuHeader = true,
            icon = "fa-solid fa-laptop",
        }
    }
    QBCore.Functions.TriggerCallback('l2s-bossmenu:server:GetAllBussiness', function(business)
        for k, v in pairs(business) do
            local owneed = 'Not Owned'
            if v.citizenid ~= 'none' then
                owneed = v.citizenid
            end
            businessMenu[#businessMenu + 1] = {
                    header = v.label ..' - '..v.type,
                    txt = "Price: " .. v.price .. "$ - Owner: " .. owneed,
                    icon = "fa-solid fa-user-check",
                    params = {
                        event = "l2s-bossmenu:server:EditBussiness",
                        args = v,
                    }
                }
        end
        exports['l2s-ui']:openMenu(businessMenu)
    end)

end)

RegisterNetEvent('l2s-bossmenu:server:EditBussiness', function(data)
    local businessMenu = {
        {
            header = "Mayor Menu",
            isMenuHeader = true,
            icon = "fa-solid fa-laptop",
        },
        {
            header = "Edit Price",
            icon = "fa-solid fa-dollar-sign",
            txt = 'Current: $'..data.price,
            params = {
                event = "l2s-bossmenu:client:EditPrice",
                args = data,
            }
        },
        {
            header = "Edit Label",
            icon = "fa-solid fa-tag",
            txt = 'Current: '..data.label,
            params = {
                event = "l2s-bossmenu:client:EditLabel",
                args = data,
            }
        },

    }
    if data.citizenid ~= 'none' then
        businessMenu[#businessMenu+1] = {
            header = "Transfer Ownership",
            icon = "fa-solid fa-laptop",
            txt = 'Giving ownership to someone without any financial compensation (must be close to you)',
            params = {
                event = "l2s-bossmenu:client:TransferOwnership",
                args = data,
            }
        }
    else
        businessMenu[#businessMenu+1] = {
            header = "Give Ownership",
            icon = "fa-solid fa-laptop",
            txt = 'Transfer of ownership from one person to another',
            params = {
                event = "l2s-bossmenu:client:TransferOwnership",
                args = data,
            }
        }
    end
    exports['l2s-ui']:openMenu(businessMenu)

end)

RegisterNetEvent('l2s-bossmenu:client:TransferOwnership', function(data)
    local withdraw = exports['l2s-ui']:OpenInputDialog({
        header = "Transfer "..data.label.." Ownership - Write (none) if you want business without ownership",
        submitText = "Confirm",
        inputs = {
            {
                type = 'text',
                isRequired = true,
                name = 'amount',
                text = 'New Owner CitizenID'
            }
        }
    })
    if withdraw then
        if not withdraw.amount then return end
        TriggerServerEvent("l2s-bossmenu:server:TransferOwnership", data, withdraw.amount)
    end
end)

RegisterNetEvent('l2s-bossmenu:client:EditPrice', function(data)
    local withdraw = exports['l2s-ui']:OpenInputDialog({
        header = "Edit "..data.label.." Business Price <br> Current: $" .. data.price,
        submitText = "Confirm",
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'amount',
                text = 'New Price'
            }
        }
    })
    if withdraw then
        if not withdraw.amount then return end
        TriggerServerEvent("l2s-bossmenu:server:EditBussinessPrice", data, tonumber(withdraw.amount))
    end
end)

RegisterNetEvent('l2s-bossmenu:client:EditLabel', function(data)
    local withdraw = exports['l2s-ui']:OpenInputDialog({
        header = "Edit "..data.label.." Business Label",
        submitText = "Confirm",
        inputs = {
            {
                type = 'text',
                isRequired = true,
                name = 'amount',
                text = 'New Label'
            }
        }
    })
    if withdraw then
        if not withdraw.amount or withdraw.amount == nil then return end
        TriggerServerEvent("l2s-bossmenu:server:EditBussinessLabel", data, withdraw.amount)
    end
end)
