local QBCore = exports['qb-core']:GetCoreObject()
local PlayerJob = QBCore.Functions.GetPlayerData().job
local shownBossMenu = false



local function comma_value(amount)
    local formatted = amount
    while true do
        local k
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then
            break
        end
    end
    return formatted
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        PlayerJob = QBCore.Functions.GetPlayerData().job
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

RegisterNetEvent('l2s-bossmenu:client:OpenMenu', function()
    if not PlayerJob.name or not PlayerJob.isboss then return end

    local bossMenu = {
        {
            header = "Boss Menu - " .. string.upper(PlayerJob.label),
            icon = "fa-solid fa-circle-info",
            isMenuHeader = true,
        },
        {
            header = "Manage Employees",
            icon = "fa-solid fa-list",
            txt = "Check your Employees List",
            params = {
                event = "l2s-bossmenu:client:employeelist",
            }
        },
        {
            header = "Hire Employees",
            icon = "fa-solid fa-hand-holding",
            txt = "Hire Nearby Civilians",
            params = {
                event = "l2s-bossmenu:client:HireMenu",
            }
        },
        {
            header = "Storage Access",
            txt = "Open Storage",
            icon = "fa-solid fa-box-open",
            params = {
                event = "l2s-bossmenu:server:OpenStash",
                isServer = true,
                args = PlayerJob.name,
            }
        },
        -- {
        --     header = "Outfits",
        --     txt = "See Saved Outfits",
        --     icon = "fa-solid fa-shirt",
        --     params = {
        --         event = "l2s-bossmenu:client:Wardrobe",
        --     }
        -- },
        {
            header = "Money Management",
            txt = "Check your Company Balance",
            icon = "fa-solid fa-sack-dollar",
            params = {
                event = "l2s-bossmenu:client:SocietyMenu",
            }
        },
    }
    exports['l2s-ui']:openMenu(bossMenu)
end)

RegisterNetEvent('l2s-bossmenu:client:employeelist', function()
    local EmployeesMenu = {
        {
            header = "Manage Employees",
            isMenuHeader = true,
            txt = string.upper(PlayerJob.label),
            icon = "fa-solid fa-circle-info",
        },
    }
    QBCore.Functions.TriggerCallback('l2s-bossmenu:server:GetEmployees', function(cb)
        for _, v in pairs(cb) do
            EmployeesMenu[#EmployeesMenu + 1] = {
                header = v.name,
                txt = v.grade.name,
                icon = v.profile_image or "fa-solid fa-circle-user",
                params = {
                    event = "l2s-bossmenu:client:ManageEmployee",
                    args = {
                        player = v,
                        work = PlayerJob
                    }
                }
            }
        end
        EmployeesMenu[#EmployeesMenu + 1] = {
            header = "Back",
            icon = "fa-solid fa-angle-left",
            params = {
                event = "l2s-bossmenu:client:OpenMenu",
            }
        }
        exports['l2s-ui']:openMenu(EmployeesMenu)
    end, PlayerJob.name)
end)

RegisterNetEvent('l2s-bossmenu:client:ManageEmployee', function(data)
    local EmployeeMenu = {
        {
            header = "Manage " .. data.player.name,
            isMenuHeader = true,
            txt = string.upper(PlayerJob.label),
            icon = "fa-solid fa-circle-info"
        },
    }
    for k, v in pairs(QBCore.Shared.Jobs[data.work.name].grades) do
        EmployeeMenu[#EmployeeMenu + 1] = {
            header = QBCore.Shared.Jobs[data.work.name]['grades'][''..k..''].name,
            txt = "Grade: " .. k,
            params = {
                isServer = true,
                event = "l2s-bossmenu:server:GradeUpdate",
                icon = "fa-solid fa-file-pen",
                args = {
                    cid = data.player.empSource,
                    grade = tonumber(k),
                    gradename = v.name
                }
            }
        }
    end
    EmployeeMenu[#EmployeeMenu + 1] = {
        header = "Fire Employee",
        icon = "fa-solid fa-user-large-slash",
        params = {
            isServer = true,
            event = "l2s-bossmenu:server:FireEmployee",
            args = data.player.empSource
        }
    }
    EmployeeMenu[#EmployeeMenu + 1] = {
        header = "Back",
        icon = "fa-solid fa-angle-left",
        params = {
            event = "l2s-bossmenu:client:OpenMenu",
        }
    }
    exports['l2s-ui']:openMenu(EmployeeMenu)
end)



RegisterNetEvent('l2s-bossmenu:client:Wardrobe', function()
    TriggerEvent('l2s-clothing:client:openOutfitMenu')
end)

RegisterNetEvent('l2s-bossmenu:client:HireMenu', function()
    local HireMenu = {
        {
            header = "Hire Employees",
            txt = string.upper(PlayerJob.label),
            isMenuHeader = true,
            icon = "fa-solid fa-circle-info",
        },
    }
    QBCore.Functions.TriggerCallback('l2s-bossmenu:getplayers', function(players)
        for _, v in pairs(players) do
            if v and v ~= PlayerId() then
                HireMenu[#HireMenu + 1] = {
                    header = v.name,
                    txt = "Citizen ID: " .. v.citizenid .. " - ID: " .. v.sourceplayer,
                    icon = "fa-solid fa-user-check",
                    params = {
                        isServer = true,
                        event = "l2s-bossmenu:server:HireEmployee",
                        args = v.sourceplayer
                    }
                }
            end
        end
        HireMenu[#HireMenu + 1] = {
            header = "Back",
            icon = "fa-solid fa-angle-left",
            params = {
                event = "l2s-bossmenu:client:OpenMenu",
            }
        }
        exports['l2s-ui']:openMenu(HireMenu)
    end)
end)

RegisterNetEvent('l2s-bossmenu:client:SocietyMenu', function()
    QBCore.Functions.TriggerCallback('l2s-bossmenu:server:GetAccount', function(cb)
        local SocietyMenu = {
            {
                header = "Balance: $" .. comma_value(cb),
                isMenuHeader = true,
                string.upper(PlayerJob.label),
                icon = "fa-solid fa-circle-info",
            },

            {
                header = "Deposit",
                icon = "fa-solid fa-money-bill-transfer",
                txt = "Deposit Money into account",
                params = {
                    event = "l2s-bossmenu:client:SocetyDeposit",
                    args = comma_value(cb)
                }
            },
            {
                header = "Withdraw",
                icon = "fa-solid fa-money-bill-transfer",
                txt = "Withdraw Money from account",
                params = {
                    event = "l2s-bossmenu:client:SocetyWithDraw",
                    args = comma_value(cb)
                }
            },
            {
                header = "Back",
                icon = "fa-solid fa-angle-left",
                params = {
                    event = "l2s-bossmenu:client:OpenMenu",
                }
            },
        }
        exports['l2s-ui']:openMenu(SocietyMenu)
    end, PlayerJob.name)
end)

RegisterNetEvent('l2s-bossmenu:client:SocetyDeposit', function(money)
    local deposit = exports['l2s-ui']:OpenInputDialog({
        header = "Deposit Money <br> Available Balance: $" .. money,
        submitText = "Confirm",
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'amount',
                text = 'Amount'
            }
        }
    })
    if deposit then
        if not deposit.amount then return end
        TriggerServerEvent("l2s-bossmenu:server:depositMoney", tonumber(deposit.amount))
    end
end)

RegisterNetEvent('l2s-bossmenu:client:SocetyWithDraw', function(money)
    local withdraw = exports['l2s-ui']:OpenInputDialog({
        header = "Withdraw Money <br> Available Balance: $" .. money,
        submitText = "Confirm",
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'amount',
                text = 'Amount'
            }
        }
    })
    if withdraw then
        if not withdraw.amount then return end
        TriggerServerEvent("l2s-bossmenu:server:withdrawMoney", tonumber(withdraw.amount))
    end
end)

-- MAIN THREAD
CreateThread(function()
    for job, zones in pairs(Config.BossMenuZones) do
        for index, data in ipairs(zones) do
            exports['qb-target']:AddBoxZone(job.."-JBossMenu-"..index, data.coords, data.length, data.width, {
                name = job.."-JBossMenu-"..index,
                heading = data.heading,
                -- debugPoly = true,
                minZ = data.minZ,
                maxZ = data.maxZ,
            }, {
                options = {
                    {
                        type = "client",
                        event = "l2s-bossmenu:client:OpenMenu",
                        icon = "fas fa-sign-in-alt",
                        label = "Boss Menu",
                        canInteract = function() return job == PlayerJob.name and PlayerJob.isboss end,
                    },
                    {
                        type = "client",
                        event = "l2s-justice:client:MayorMenu",
                        icon = "fas fa-laptop",
                        label = "Mayor Menu",
                        job = {['justice']= 6},
                        canInteract = function() return job == PlayerJob.name and PlayerJob.isboss end,
                    },
                },
                distance = 2.5
            })
        end
    end
end)
--------