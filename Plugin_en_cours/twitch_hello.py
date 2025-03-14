import socket
import threading
import time
import obspython as obs

# Variables globales pour la configuration
server = "irc.chat.twitch.tv"
port = 6667
nickname = ""
token = ""
channel = ""

irc_socket = None
running = False

def connect_to_twitch():
    global irc_socket, running
    try:
        irc_socket = socket.socket()
        irc_socket.connect((server, port))
        irc_socket.send(f"PASS {token}\r\n".encode('utf-8'))
        irc_socket.send(f"NICK {nickname}\r\n".encode('utf-8'))
        irc_socket.send(f"JOIN #{channel}\r\n".encode('utf-8'))
        obs.script_log(obs.LOG_INFO, "Connecté à Twitch IRC")
    except Exception as e:
        obs.script_log(obs.LOG_ERROR, f"Erreur de connexion : {e}")
        return

    running = True
    while running:
        try:
            response = irc_socket.recv(2048).decode('utf-8')
            if response.startswith("PING"):
                irc_socket.send("PONG :tmi.twitch.tv\r\n".encode('utf-8'))
            else:
                # Vérifie si la commande !hello apparaît dans le message
                if "!hello" in response:
                    obs.script_log(obs.LOG_INFO, "Commande !hello reçue dans le chat!")
        except Exception as e:
            obs.script_log(obs.LOG_ERROR, f"Erreur lors de la réception : {e}")
            break

def start_thread():
    thread = threading.Thread(target=connect_to_twitch)
    thread.daemon = True
    thread.start()

def stop_thread():
    global running
    running = False
    if irc_socket:
        irc_socket.close()

# OBS API : Description du script
def script_description():
    return "Script Python qui se connecte à Twitch et réagit à la commande !hello"

# Mise à jour des paramètres du script
def script_update(settings):
    global nickname, token, channel
    nickname = obs.obs_data_get_string(settings, "nickname")
    token = obs.obs_data_get_string(settings, "token")
    channel = obs.obs_data_get_string(settings, "channel")
    obs.script_log(obs.LOG_INFO, f"Paramètres mis à jour : {nickname}, {channel}")

# Création des propriétés à configurer dans l’interface d’OBS
def script_properties():
    props = obs.obs_properties_create()
    obs.obs_properties_add_text(props, "nickname", "Nickname", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "token", "OAuth Token", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_text(props, "channel", "Channel (sans #)", obs.OBS_TEXT_DEFAULT)
    return props

# Chargement et déchargement du script
def script_load(settings):
    start_thread()
    obs.script_log(obs.LOG_INFO, "Script Python chargé et thread démarré")

def script_unload():
    stop_thread()
    obs.script_log(obs.LOG_INFO, "Script Python arrêté")
