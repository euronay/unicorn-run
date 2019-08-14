local states = {}

states.standing = {}
function states.standing:message(agent, event)
    if event == "fall" then
        agent:setState("falling")
    elseif event == "jump" then
        agent:setState("jumping")
    elseif event == "move" then
        agent:setState("running")
    end
end

states.running = {}
function states.running:message(agent, event)
    if event == "fall" then
        agent:setState("falling")
    elseif event == "jump" then
        agent:setState("jumping")
    elseif event == "stop" then
        agent:setState("standing")
    end
end

states.falling = {}
function states.falling:message(agent, event)
    if event == "hitground" then
        local xm = agent.xVelocity
        if xm == 0 then
            agent:setState("standing")
        else
            agent:setState("running")
        end
    elseif event == "jump" then
        agent:setState("jumping")
    end
end

states.jumping = {}
function states.jumping:message(agent, event)
    if event == "hitroof" then
        agent:setState("falling")
    elseif event == "hitground" then
        local xm = agent.xVelocity
        if xm == 0 then
            agent:setState("standing")
        else
            agent:setState("running")
        end
    end
end

return states
