#!/bin/bash
# ==============================================================================
# GRAINSMART CAFE - KITCHEN DISPLAY SYSTEM (KDS)
# ==============================================================================
SET_DIR="/srv/grainsmart"
KITCHEN_DIR="$SET_DIR/kitchen"
COMPLETED_DIR="$KITCHEN_DIR/completed"

# Ensure target directories exist and permissions are open
mkdir -p "$KITCHEN_DIR" "$COMPLETED_DIR" 2>/dev/null
chmod -R 777 "$KITCHEN_DIR" 2>/dev/null

COOK_USER="${ACTIVE_USER:-$(whoami)}"

shopt -s nullglob

while true; do
    clear
    echo "=================================================================="
    echo "            GRAINSMART CAFE - KITCHEN DISPLAY SYSTEM              "
    echo "=================================================================="
    echo "Cook On Duty: $COOK_USER | Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "------------------------------------------------------------------"

    # Fetch all active pending order tickets
    TICKETS=("$KITCHEN_DIR"/ticket_ORD-*.txt)

    if [ ${#TICKETS[@]} -eq 0 ]; then
        echo " [!] No pending orders in kitchen queue."
        echo "------------------------------------------------------------------"
        echo " [1] Refresh Queue"
        echo " [2] View Completed & Denied Order History"
        echo " [0] Exit Kitchen System"
        echo "=================================================================="
        read -p "Select Option [0-2]: " MAIN_OPT
        case "$MAIN_OPT" in
            1) continue ;;
            2)
                clear
                echo "=================================================================="
                echo "                   COMPLETED & DENIED HISTORY                     "
                echo "=================================================================="
                DONE_TICKETS=("$COMPLETED_DIR"/ticket_ORD-*.txt)
                if [ ${#DONE_TICKETS[@]} -eq 0 ]; then
                    echo " No past tickets found in history."
                else
                    for t in "${DONE_TICKETS[@]}"; do
                        echo "--- $(basename "$t") ---"
                        cat "$t"
                        echo "------------------------------------------------------------------"
                    done
                fi
                echo "=================================================================="
                read -p "Press [ENTER] to return..."
                ;;
            0)
                echo "Exiting Kitchen System..."
                sleep 1
                break
                ;;
            *) continue ;;
        esac
    else
        echo " PENDING ORDERS QUEUE (${#TICKETS[@]} active):"
        echo "------------------------------------------------------------------"
        count=0
        for ticket in "${TICKETS[@]}"; do
            count=$((count + 1))
            fname=$(basename "$ticket")
            ord_id=${fname//ticket_/}
            ord_id=${ord_id//.txt/}
            time_stamp=$(grep "Time" "$ticket" | cut -d':' -f2- | xargs)
            echo " [$count] $ord_id | Time: $time_stamp"
        done
        echo "------------------------------------------------------------------"
        echo " [0] Exit Kitchen System"
        echo "=================================================================="
        read -p "Select Order Number to Process [1-$count] (or 0 to exit): " SEL_NUM

        if [ "$SEL_NUM" -eq 0 ] 2>/dev/null; then
            echo "Exiting Kitchen System..."
            sleep 1
            break
        fi

        if [[ "$SEL_NUM" =~ ^[0-9]+$ ]] && [ "$SEL_NUM" -ge 1 ] && [ "$SEL_NUM" -le "$count" ]; then
            SELECTED_TICKET="${TICKETS[$((SEL_NUM - 1))]}"
            TICKET_FILE=$(basename "$SELECTED_TICKET")

            clear
            echo "=================================================================="
            echo "                     PROCESSING ORDER TICKET                      "
            echo "=================================================================="
            cat "$SELECTED_TICKET"
            echo "=================================================================="
            echo " KITCHEN ACTIONS & COMMAND GUIDE:"
            echo "  [A] ACCEPT ORDER  -> Fulfills order, marks as SERVED & archives ticket"
            echo "  [D] DENY ORDER    -> Rejects order, asks for reason & cancels ticket"
            echo "  [B] BACK TO QUEUE -> Returns to order list without modifying ticket"
            echo "=================================================================="
            read -p "Enter Command Key [A=Accept / D=Deny / B=Back]: " ACTION

            case "${ACTION,,}" in
                a)
                    echo "" >> "$SELECTED_TICKET"
                    echo "STATUS: [ACCEPTED / SERVED] - Cook: $COOK_USER ($(date '+%Y-%m-%d %H:%M:%S'))" >> "$SELECTED_TICKET"
                    mv "$SELECTED_TICKET" "$COMPLETED_DIR/$TICKET_FILE"
                    echo -e "\n[✓] ORDER ACCEPTED! Ticket marked as SERVED and archived."
                    sleep 1.5
                    ;;
                d)
                    echo ""
                    read -p "Enter Reason for Denial (e.g. Out of Ingredients): " DENY_REASON
                    [ -z "$DENY_REASON" ] && DENY_REASON="Kitchen unable to fulfill"
                    echo "" >> "$SELECTED_TICKET"
                    echo "STATUS: [DENIED / CANCELLED] - Reason: $DENY_REASON - Cook: $COOK_USER ($(date '+%Y-%m-%d %H:%M:%S'))" >> "$SELECTED_TICKET"
                    mv "$SELECTED_TICKET" "$COMPLETED_DIR/$TICKET_FILE"
                    echo -e "\n[!] ORDER DENIED! Ticket marked as CANCELLED and archived."
                    sleep 2
                    ;;
                b|0)
                    continue
                    ;;
                *)
                    echo "[!] Invalid command key. Please enter A, D, or B."
                    sleep 1.5
                    ;;
            esac
        fi
    fi
done