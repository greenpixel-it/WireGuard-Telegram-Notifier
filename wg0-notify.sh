#!/bin/bash

# Configurazione
TELEGRAM_BOT_TOKEN="put here your telegram token"
TELEGRAM_CHAT_ID="put here your chat id"
WG_INTERFACE="wg0"  # L'interfaccia WireGuard (solitamente wg0)
EXECUTION_INTERVAL="10" # Delay per l'esecuzione in loop del controllo
LAST_HANDSHAKE_TIMEOUT_MAX="240" # Massimo tempo per definire se il client potrebbe essere ancora connesso

CONNECTED_PEERS=()  # Array con i peer attualmente collegati

# Funzione per mandare il messaggio di notifica
telegram_send_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="${TELEGRAM_CHAT_ID}" \
        -d text="${message}" \
        -d parse_mode="Markdown" > /dev/null 2>&1
}

# Funzione per controllare se un peer ènella lista dei connessi
check_peer_connected_peers() {
    local id="$1"
    for peer in "${CONNECTED_PEERS[@]}"; do
        if [[ "$peer" == "$id" ]]; then
            return 0
        fi
    done
    return 1
}

# Funzione per rimuovere un peer dall'array dei connessi
remove_peer_connected_peers() {
    local id="$1"
    for i in "${!CONNECTED_PEERS[@]}"; do
        if [[ "${CONNECTED_PEERS[i]}" == "$id" ]]; then
            unset 'CONNECTED_PEERS[i]'
            #echo "Peer rimosso: $id"
            break
        fi
    done
    CONNECTED_PEERS=("${CONNECTED_PEERS[@]}")
}

# funzione per estrarre ed associare un nome al peer id
get_peer_comment() {
    local peer_id="$1"
    local config_file="/etc/wireguard/wg0.conf"

    local comment=$(awk '
    BEGIN { found = 0 }
    $1 == "PublicKey" && $3 == "'"$peer_id"'" { found = 1 } 
    found && /^#/ { sub(/^# */, "", $0); print; exit }
    ' "$config_file")

    if [ -z "$comment" ]; then
        echo "NO id ... "
    else
        echo "$comment"
    fi
}


#echo -e "\nINIZIO\n"

while true; do
    CURRENT_TIMESTAMP=$(date +%s)

    WG_DUMP=$(wg show $WG_INTERFACE dump)

    while IFS= read -r line; do
        PEER_PUBLIC_KEY=$(echo "$line" | awk '{print $1}')
        LATEST_HANDSHAKE=$(echo "$line" | awk '{print $5}')
        PEER_ENDPOINT=$(echo "$line" | awk '{print $3}')

        if [ "$LATEST_HANDSHAKE" -gt 0 ]; then
            TIME_SINCE_LAST_HANDSHAKE=$((CURRENT_TIMESTAMP - LATEST_HANDSHAKE))
        else
            TIME_SINCE_LAST_HANDSHAKE="99999"  # Se non c'è handshake
        fi

        PEER_IP=$(echo "$PEER_ENDPOINT" | sed 's/:.*//')

        #echo "Peer ID: $PEER_PUBLIC_KEY"
        #echo "$(get_peer_comment $PEER_PUBLIC_KEY)"
        #echo "Last handshake: $TIME_SINCE_LAST_HANDSHAKE secondi"
        #echo "Last Known IP : $PEER_IP"

        if [ "$TIME_SINCE_LAST_HANDSHAKE" -lt "$LAST_HANDSHAKE_TIMEOUT_MAX" ]; then
                #echo "tempo minore di $LAST_HANDSHAKE_TIMEOUT_MAX"
                if ! check_peer_connected_peers "$PEER_PUBLIC_KEY" ; then
                #       echo "peer non esiste .. lo aggiungo"
                        telegram_send_message "%E2%9d%97 USER $(get_peer_comment $PEER_PUBLIC_KEY) is CONNECTED to WireGuard VPN from  $PEER_IP"
                        CONNECTED_PEERS+=("$PEER_PUBLIC_KEY")
                #else
                #       echo "peer esiste .. apposto"
                fi
        else
                #echo "tempo maggiore di $LAST_HANDSHAKE_TIMEOUT_MAX"
                if check_peer_connected_peers "$PEER_PUBLIC_KEY" ; then
                #       echo "peer esiste .. lo rimuovo"

                        telegram_send_message "%E2%9d%95 USER $(get_peer_comment $PEER_PUBLIC_KEY) is DISCONNECTED to WireGuard VPN from  $PEER_IP"
                        remove_peer_connected_peers "$PEER_PUBLIC_KEY"
                #else
                #       echo "peer non esiste  .. apposto"
                fi
        fi

        #echo "----------------------------"
    done < <(echo "$WG_DUMP" | tail -n +2)

    #echo "Elementi dell'array: ${CONNECTED_PEERS[@]}"
    #echo -e "\nFINE\n\n"

    sleep 5
done

