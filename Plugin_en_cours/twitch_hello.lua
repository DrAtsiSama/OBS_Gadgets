local socket = require("socket")

local server = "irc.chat.twitch.tv"
local port = 6667
local nickname = ""
local token = ""
local channel = ""

local irc_socket = nil
local running = false

function connect_to_twitch()
    irc_socket = socket.tcp()
    local success, err = irc_socket:connect(server, port)
    if not success then
        obs.script_log(obs.LOG_ERROR, "Erreur de connexion : " .. tostring(err))
        return
    end
    irc_socket:send("PASS " .. token .. "\r\n")
    irc_socket:send("NICK " .. nickname .. "\r\n")
    irc_socket:send("JOIN #" .. channel .. "\r\n")
    obs.script_log(obs.LOG_INFO, "Connecté à Twitch IRC (Lua)")
    running = true

    while running do
        local response, err = irc_socket:receive("*l")
        if response then
            if string.find(response, "PING") then
                irc_socket:send("PONG :tmi.twitch.tv\r\n")
            elseif string.find(response, "!hello") then
                obs.script_log(obs.LOG_INFO, "Commande !hello reçue dans le chat! (Lua)")
            end
        else
            obs.script_log(obs.LOG_ERROR, "Erreur lors de la réception : " .. tostring(err))
            break
        end
        socket.sleep(0.1)
    end
end

local thread_started = false

-- Pour Lua, nous utilisons un timer OBS afin de lancer la connexion une seule fois.
function start_connection()
    if not thread_started then
        thread_started = true
        -- Lancer la connexion dans une fonction non bloquante via une coroutine
        local co = coroutine.create(connect_to_twitch)
        coroutine.resume(co)
    end
end

function stop_connection()
    running = false
    if irc_socket then
        irc_socket:close()
    end
end

function script_description()
    return "Script Lua qui se connecte à Twitch et réagit à la commande !hello"
end

function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "nickname", "Nickname", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "token", "OAuth Token", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "channel", "Channel (sans #)", obs.OBS_TEXT_DEFAULT)
    return props
end

function script_update(settings)
    nickname = obs.obs_data_get_string(settings, "nickname")
    token = obs.obs_data_get_string(settings, "token")
    channel = obs.obs_data_get_string(settings, "channel")
    obs.script_log(obs.LOG_INFO, "Paramètres mis à jour (Lua) : " .. nickname .. ", " .. channel)
end

function script_load(settings)
    -- Lancer la connexion après chargement du script
    start_connection()
    obs.script_log(obs.LOG_INFO, "Script Lua chargé")
end

function script_unload()
    stop_connection()
    obs.script_log(obs.LOG_INFO, "Script Lua arrêté")
end
