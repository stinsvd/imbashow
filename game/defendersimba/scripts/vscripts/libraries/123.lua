-- Timers library
-- Author: BMD

Timers = {}

-- Create a timer
function Timers:CreateTimer(name, args)
    if type(name) == "function" then
        args = {callback = name}
        name = DoUniqueString("timer")
    elseif type(name) == "number" then
        args = {endTime = name, callback = args}
        name = DoUniqueString("timer")
    elseif type(name) == "table" then
        args = name
        name = DoUniqueString("timer")
    end

    if not args.callback then
        print("Invalid timer created: "..name)
        return
    end

    args.endTime = args.endTime or GameRules:GetGameTime()

    Timers[name] = args

    Timers:Think()
    return name
end

-- Think function
function Timers:Think()
    if not Timers._running then
        Timers._running = true
        Timers:_InternalThink()
    end
end

-- Internal think function
function Timers:_InternalThink()
    local now = GameRules:GetGameTime()
    for k,v in pairs(Timers) do
        if type(v) == "table" and v.endTime <= now then
            Timers[k] = nil
            local status, nextCall = pcall(v.callback, GameRules:GetGameTime() - v.endTime)

            if status and nextCall then
                v.endTime = v.endTime + nextCall
                Timers[k] = v
            elseif not status then
                print('[Timers] Timer error: '..nextCall)
            end
        end
    end

    Timers._running = false
end
