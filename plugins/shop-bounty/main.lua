function GetPluginAuthor()
    return "DeadPool"
end

function GetPluginVersion()
    return "v1.0.0"
end

function GetPluginName()
    return "Shop System - Bounty player"
end

function GetPluginWebsite()
    return "https://github.com/DeadPoolCS2/shop-bounty"
end

local bountyTarget = nil
local bountyReward = 0
local roundActive = false

local function selectBountyTarget()
    local players = {}
    for playerid = 0, playermanager:GetPlayerCap() - 1 do
        local player = GetPlayer(playerid)
        if player and player:IsValid() and not player:IsFakeClient() and IsPlayerAlive(playerid) then
            table.insert(players, playerid)
        end
    end

    if #players == 0 then return end

    bountyTarget = players[math.random(#players)]
    bountyReward = math.random(config:Fetch("bounty.min_reward"), config:Fetch("bounty.max_reward"))

    local targetPlayer = GetPlayer(bountyTarget)
    playermanager:SendMsg(MessageType.Chat, config:Fetch("shop.bounty.prefix") .. FetchTranslation("bounty.new_target")
        :gsub("{PLAYER_NAME}", targetPlayer:CBasePlayerController().PlayerName)
        :gsub("{REWARD}", bountyReward)
    )
end

AddEventHandler("OnRoundStart", function()
    local totalPlayers = 0

    for playerid = 0, playermanager:GetPlayerCap() - 1 do
        local player = GetPlayer(playerid)
        if player and player:IsValid() and not player:IsFakeClient() then
            totalPlayers = totalPlayers + 1
        end
    end

    if totalPlayers < config:Fetch("bounty.min_players") then
        playermanager:SendMsg(MessageType.Chat, config:Fetch("shop.bounty.prefix"), FetchTranslation("bounty.not_enough_players"):gsub("{MIN_PLAYERS}", config:Fetch("bounty.min_players")))
        return
    end

    local randomChance = math.random(0, 100)
    if randomChance <= config:Fetch("bounty.chance_to_start") then
        selectBountyTarget()
    end
end)



AddEventHandler("OnRoundEnd", function()
    if roundActive and bountyTarget then
        local targetPlayer = GetPlayer(bountyTarget)
        if targetPlayer and targetPlayer:IsValid() and IsPlayerAlive(bountyTarget) then
            local survivorReward = math.floor(bountyReward / 2)
            exports["shop-core"]:GiveCredits(bountyTarget, survivorReward)

            playermanager:SendMsg(MessageType.Chat, config:Fetch("shop.bounty.prefix") .. FetchTranslation("bounty.survived")
                :gsub("{PLAYER_NAME}", targetPlayer:CBasePlayerController().PlayerName)
                :gsub("{REWARD}", survivorReward)
            )
        end
    end
    bountyTarget = nil
    bountyReward = 0
    roundActive = false
end)

AddEventHandler("OnPlayerDeath", function(event, victimid, attackerid)
    if not roundActive or not bountyTarget then return end

    if victimid == bountyTarget and attackerid ~= victimid and attackerid ~= -1 then
        local attacker = GetPlayer(attackerid)
        if attacker and attacker:IsValid() then
            exports["shop-core"]:GiveCredits(attackerid, bountyReward)

            playermanager:SendMsg(MessageType.Chat, config:Fetch("shop.bounty.prefix") .. FetchTranslation("bounty.claimed")
                :gsub("{KILLER}", attacker:CBasePlayerController().PlayerName)
                :gsub("{TARGET}", GetPlayer(victimid):CBasePlayerController().PlayerName)
                :gsub("{REWARD}", bountyReward)
            )
        end
        bountyTarget = nil
    end
end)
