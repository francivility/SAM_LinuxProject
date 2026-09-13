#!/bin/bash
# ==============================================================================
# GRAINSMART CAFE - POS SYSTEM WITH AUTOMATED INVENTORY DEDUCTION
# ==============================================================================
SET_DIR="/srv/grainsmart"
SALES_FILE="$SET_DIR/orders/sales.csv"
KITCHEN_DIR="$SET_DIR/kitchen"

if [ -r "$SET_DIR/inventory/stock.csv" ]; then
    STOCK_FILE="$SET_DIR/inventory/stock.csv"
elif [ -r "data/inventory/stock.csv" ]; then
    STOCK_FILE="data/inventory/stock.csv"
else
    echo "[ERROR] Stock database file not found in $SET_DIR/inventory/stock.csv"
    exit 1
fi

CASHIER_USER="${ACTIVE_USER:-$(whoami)}"

# Function to deduct purchased items from stock.csv
deduct_stock() {
    local item_name="$1"
    local qty_sold="$2"
    local temp_file
    temp_file=$(mktemp)

    while IFS=',' read -r id name cat price stock; do
        id=$(echo "$id" | tr -d '\r')
        name=$(echo "$name" | tr -d '\r')
        cat=$(echo "$cat" | tr -d '\r')
        price=$(echo "$price" | tr -d '\r')
        stock=$(echo "$stock" | tr -d '\r')

        if [ "$name" == "$item_name" ]; then
            new_stock=$((stock - qty_sold))
            if [ $new_stock -lt 0 ]; then new_stock=0; fi
            echo "$id,$name,$cat,$price,$new_stock" >> "$temp_file"
        else
            echo "$id,$name,$cat,$price,$stock" >> "$temp_file"
        fi
    done < "$STOCK_FILE"

    cp "$temp_file" "$STOCK_FILE" 2>/dev/null
    [ -f "data/inventory/stock.csv" ] && cp "$temp_file" "data/inventory/stock.csv" 2>/dev/null
    rm -f "$temp_file"
}

# CUSTOMER ORDER LOOP
while true; do
    CART_ITEMS=()
    CART_QTYS=()
    CART_PRICES=()
    SUBTOTAL=0

    # STEP 1: ADD PRODUCTS & QUANTITY
    while true; do
        clear
        echo "=================================================================="
        echo "                 GRAINSMART CAFE - POS TERMINAL                   "
        echo "=================================================================="
        echo "Cashier On Duty: $CASHIER_USER"
        echo "------------------------------------------------------------------"
        if [ ${#CART_ITEMS[@]} -gt 0 ]; then
            echo "CURRENT ORDER SUMMARY (${#CART_ITEMS[@]} items):"
            for i in "${!CART_ITEMS[@]}"; do
                item_tot=$((${CART_QTYS[$i]} * ${CART_PRICES[$i]}))
                printf "  - %2dx %-32s (P%d each) = P%d\n" "${CART_QTYS[$i]}" "${CART_ITEMS[$i]}" "${CART_PRICES[$i]}" "$item_tot"
            done
            echo "------------------------------------------------------------------"
            echo "  CURRENT SUBTOTAL: P$SUBTOTAL"
            echo "------------------------------------------------------------------"
        fi
        echo " SELECT CATEGORY:"
        echo " [1] Cafe Beverages"
        echo " [2] Add-ons & Sinkers"
        echo " [3] Prepared Snacks & Meals"
        echo " [0] Cancel & Exit POS"
        echo "=================================================================="
        read -p "Select Category Option [0-3]: " CAT_CHOICE

        case "$CAT_CHOICE" in
            1) FILTER="Beverages" ;;
            2) FILTER="Sinkers" ;;
            3) FILTER="Meals" ;;
            0)
                echo "Exiting POS Terminal..."
                exit 0
                ;;
            *)
                echo "Invalid selection."
                sleep 1
                continue
                ;;
        esac

        clear
        echo "=================================================================="
        echo " CATEGORY: $FILTER"
        echo "=================================================================="
        echo " #  | ITEM NAME                              | PRICE | STOCK LEFT"
        echo "------------------------------------------------------------------"

        declare -a OPT_NAMES
        declare -a OPT_PRICES
        declare -a OPT_STOCKS
        opt_count=0

        while IFS=',' read -r id name cat price stock; do
            id=$(echo "$id" | tr -d '\r')
            name=$(echo "$name" | tr -d '\r')
            cat=$(echo "$cat" | tr -d '\r')
            price=$(echo "$price" | tr -d '\r')
            stock=$(echo "$stock" | tr -d '\r')

            if [ "$cat" == "$FILTER" ]; then
                opt_count=$((opt_count + 1))
                OPT_NAMES[$opt_count]="$name"
                OPT_PRICES[$opt_count]="$price"
                OPT_STOCKS[$opt_count]="$stock"
                printf " [%2d] %-38s | P%-4s | %s units\n" "$opt_count" "$name" "$price" "$stock"
            fi
        done < "$STOCK_FILE"

        echo "------------------------------------------------------------------"
        echo " [0] Back to Categories"
        echo "=================================================================="
        read -p "Select Item Number [0-$opt_count]: " ITEM_CHOICE

        if [ "$ITEM_CHOICE" -eq 0 ] 2>/dev/null || [ "$ITEM_CHOICE" -gt "$opt_count" ]; then
            continue
        fi

        SEL_NAME="${OPT_NAMES[$ITEM_CHOICE]}"
        SEL_PRICE="${OPT_PRICES[$ITEM_CHOICE]}"
        SEL_STOCK="${OPT_STOCKS[$ITEM_CHOICE]}"

        if [ "$SEL_STOCK" -le 0 ]; then
            echo -e "\n[!] '$SEL_NAME' is OUT OF STOCK!"
            sleep 1.5
            continue
        fi

        read -p "Enter Quantity for '$SEL_NAME' (Max $SEL_STOCK): " QTY
        if ! [[ "$QTY" =~ ^[0-9]+$ ]] || [ "$QTY" -le 0 ]; then
            echo "[!] Invalid quantity."
            sleep 1
            continue
        fi

        if [ "$QTY" -gt "$SEL_STOCK" ]; then
            echo -e "\n[!] Insufficient stock! Only $SEL_STOCK units remaining."
            sleep 1.5
            continue
        fi

        LINE_TOTAL=$((SEL_PRICE * QTY))
        SUBTOTAL=$((SUBTOTAL + LINE_TOTAL))

        CART_ITEMS+=("$SEL_NAME")
        CART_QTYS+=("$QTY")
        CART_PRICES+=("$SEL_PRICE")

        echo -e "\n[+] Added $QTY x $SEL_NAME (P$LINE_TOTAL) to order."
        echo "------------------------------------------------------------------"

        read -p "Add another item to this order? (y/n): " ADD_MORE
        if [[ ! "$ADD_MORE" =~ ^[Yy]$ ]]; then
            break
        fi
    done

    # STEP 2: PAYMENT & CASH PROCESSING
    ORDER_ID="ORD-$((RANDOM % 8999 + 1000))"
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

    clear
    echo "=================================================================="
    echo "                   PAYMENT & CASH PROCESSING                      "
    echo "=================================================================="
    echo "Order ID : $ORDER_ID"
    echo "Cashier  : $CASHIER_USER"
    echo "Date     : $TIMESTAMP"
    echo "------------------------------------------------------------------"
    echo "QTY  | ITEM DESCRIPTION                        | UNIT   | TOTAL"
    echo "------------------------------------------------------------------"
    for i in "${!CART_ITEMS[@]}"; do
        item_total=$((${CART_QTYS[$i]} * ${CART_PRICES[$i]}))
        printf " %2d  | %-39s | P%-5d | P%d\n" "${CART_QTYS[$i]}" "${CART_ITEMS[$i]}" "${CART_PRICES[$i]}" "$item_total"
    done
    echo "------------------------------------------------------------------"
    echo "GRAND TOTAL DUE: P$SUBTOTAL"
    echo "=================================================================="

    CASH_GIVEN=0
    while true; do
        read -p "Enter Cash Received: P" CASH_GIVEN
        if [[ "$CASH_GIVEN" =~ ^[0-9]+$ ]] && [ "$CASH_GIVEN" -ge "$SUBTOTAL" ]; then
            break
        fi
        echo "[!] Insufficient cash. Total due is P$SUBTOTAL."
    done

    CHANGE=$((CASH_GIVEN - SUBTOTAL))

    # STEP 3: RECEIPT GENERATION
    clear
    echo "=================================================================="
    echo "                     GRAINSMART CAFE RECEIPT                      "
    echo "=================================================================="
    echo "Order ID : $ORDER_ID"
    echo "Cashier  : $CASHIER_USER"
    echo "Date     : $TIMESTAMP"
    echo "------------------------------------------------------------------"
    for i in "${!CART_ITEMS[@]}"; do
        item_total=$((${CART_QTYS[$i]} * ${CART_PRICES[$i]}))
        printf " %2d x %-36s @ P%-4d = P%d\n" "${CART_QTYS[$i]}" "${CART_ITEMS[$i]}" "${CART_PRICES[$i]}" "$item_total"
    done
    echo "------------------------------------------------------------------"
    echo "TOTAL DUE    : P$SUBTOTAL"
    echo "CASH TENDERED: P$CASH_GIVEN"
    echo "CHANGE DUE   : P$CHANGE"
    echo "=================================================================="
    echo "          Thank you for dining at Grainsmart Cafe!               "
    echo "=================================================================="
    echo ""
    echo ">> HAND OVER CHANGE OF P$CHANGE TO CUSTOMER <<"
    echo "------------------------------------------------------------------"
    read -p "Press [ENTER] to confirm receipt & dispatch order to kitchen..."

    # STEP 4: STOCK DEDUCTION, SALES LOGGING, KITCHEN TICKET DISPATCH
    mkdir -p "$SET_DIR/orders" "data/orders" 2>/dev/null
    for i in "${!CART_ITEMS[@]}"; do
        line_total=$((${CART_QTYS[$i]} * ${CART_PRICES[$i]}))
        echo "$TIMESTAMP,$ORDER_ID,${CART_ITEMS[$i]},${CART_QTYS[$i]},$line_total,$CASHIER_USER" >> "$SALES_FILE" 2>/dev/null
        echo "$TIMESTAMP,$ORDER_ID,${CART_ITEMS[$i]},${CART_QTYS[$i]},$line_total,$CASHIER_USER" >> "data/orders/sales.csv" 2>/dev/null

        # Deduct stock for each purchased item
        deduct_stock "${CART_ITEMS[$i]}" "${CART_QTYS[$i]}"
    done

    mkdir -p "$KITCHEN_DIR" 2>/dev/null
    TICKET_FILE="$KITCHEN_DIR/ticket_${ORDER_ID}.txt"
    cat << EOF > "$TICKET_FILE" 2>/dev/null
=== KITCHEN ORDER TICKET ===
Order ID : $ORDER_ID
Time     : $TIMESTAMP
Cashier  : $CASHIER_USER
----------------------------
EOF

    for i in "${!CART_ITEMS[@]}"; do
        echo "${CART_QTYS[$i]}x ${CART_ITEMS[$i]}" >> "$TICKET_FILE" 2>/dev/null
    done
    echo "============================" >> "$TICKET_FILE" 2>/dev/null

    echo ""
    echo "[SUCCESS] Receipt generated."
    echo "[SUCCESS] Inventory quantities updated."
    echo "[SUCCESS] Kitchen Ticket $ORDER_ID sent to kitchen queue!"
    echo "------------------------------------------------------------------"

    read -p "Process another customer order? (y/n): " NEXT_ORDER
    if [[ ! "$NEXT_ORDER" =~ ^[Yy]$ ]]; then
        echo "Exiting POS Terminal..."
        sleep 1
        break
    fi
done