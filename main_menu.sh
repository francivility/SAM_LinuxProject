#!/bin/bash
# ==============================================================================
# GRAINSMART CAFE - LOGIN & SYSTEM ROUTER
# ==============================================================================
SET_DIR="/srv/grainsmart"

if [ -r "$SET_DIR/users.csv" ]; then
    USERS_FILE="$SET_DIR/users.csv"
elif [ -r "data/users.csv" ]; then
    USERS_FILE="data/users.csv"
else
    echo "[ERROR] User database not found. Please run Step 1 setup command."
    exit 1
fi

while true; do
    clear
    echo "=================================================================="
    echo "                 GRAINSMART CAFE - POS SYSTEM                     "
    echo "=================================================================="
    echo "                     STAFF LOGIN TERMINAL                         "
    echo "=================================================================="
    echo ""
    read -p " Enter Username : " INPUT_USER
    read -sp " Enter Password : " INPUT_PASS
    echo ""
    echo "------------------------------------------------------------------"

    # Authenticate credentials
    AUTH_MATCH=$(grep "^${INPUT_USER},${INPUT_PASS}," "$USERS_FILE" 2>/dev/null)

    if [ -n "$AUTH_MATCH" ]; then
        ROLE=$(echo "$AUTH_MATCH" | cut -d',' -f3 | tr -d '\r')
        FULL_NAME=$(echo "$AUTH_MATCH" | cut -d',' -f4 | tr -d '\r')

        # Export active user environment variable for downstream scripts
        export ACTIVE_USER="$FULL_NAME ($INPUT_USER)"

        echo -e "\n[✓] Login successful! Welcome, $FULL_NAME ($ROLE)."
        sleep 1.5

        case "$ROLE" in
            manager)
                ./manager.sh
                ;;
            cashier)
                ./pos_cashier.sh
                ;;
            cook|kitchen)
                ./kitchen.sh
                ;;
            *)
                echo "[!] Unknown role assigned to user."
                sleep 2
                ;;
        esac
    else
        echo -e "\n[!] Invalid username or password. Please try again."
        sleep 1.5
    fi
done