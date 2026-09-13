#!/bin/bash
# ==============================================================================
# GRAINSMART CAFE - UNIFIED MANAGER DASHBOARD (SALES & INVENTORY)
# ==============================================================================
SET_DIR="/srv/grainsmart"

# Path Resolution for Sales and Inventory Databases
if [ -r "$SET_DIR/orders/sales.csv" ]; then
    SALES_FILE="$SET_DIR/orders/sales.csv"
elif [ -r "data/orders/sales.csv" ]; then
    SALES_FILE="data/orders/sales.csv"
else
    SALES_FILE="$SET_DIR/orders/sales.csv"
fi

if [ -r "$SET_DIR/inventory/stock.csv" ]; then
    STOCK_FILE="$SET_DIR/inventory/stock.csv"
elif [ -r "data/inventory/stock.csv" ]; then
    STOCK_FILE="data/inventory/stock.csv"
else
    STOCK_FILE="$SET_DIR/inventory/stock.csv"
fi

MANAGER_USER="${ACTIVE_USER:-$(whoami)}"
shopt -s nullglob

while true; do
    clear
    echo "=================================================================="
    echo "           GRAINSMART CAFE - UNIFIED MANAGER DASHBOARD            "
    echo "=================================================================="
    echo "Manager: $MANAGER_USER | Date: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "------------------------------------------------------------------"
    echo " FINANCIAL & SALES REPORTS:"
    echo " [1] Total Revenue & Product Sales Summary"
    echo " [2] Detailed Transaction Log History"
    echo " [3] Sales Breakdown by Cashier"
    echo "------------------------------------------------------------------"
    echo " INVENTORY & CATALOG MANAGEMENT:"
    echo " [4] View Live Stock Levels & Low Stock Warnings"
    echo " [5] Restock Product Quantity"
    echo " [6] Update Product Price"
    echo " [7] Add New Product to Menu Catalog"
    echo "------------------------------------------------------------------"
    echo " [0] Exit Dashboard"
    echo "=================================================================="
    read -p "Select Option [0-7]: " MGR_OPT

    case "$MGR_OPT" in
        1)
            clear
            echo "=================================================================="
            echo "                    TOTAL SALES & REVENUE                         "
            echo "=================================================================="
            if [ ! -s "$SALES_FILE" ]; then
                echo " [!] No sales recorded in the system yet."
            else
                TOTAL_REV=0
                TOTAL_QTY=0
                declare -A ITEM_QTY
                declare -A ITEM_REV

                while IFS=',' read -r timestamp order_id item qty line_total cashier; do
                    timestamp=$(echo "$timestamp" | tr -d '\r')
                    item=$(echo "$item" | tr -d '\r')
                    qty=$(echo "$qty" | tr -d '\r')
                    line_total=$(echo "$line_total" | tr -d '\r')

                    if [[ "$line_total" =~ ^[0-9]+$ ]]; then
                        TOTAL_REV=$((TOTAL_REV + line_total))
                        TOTAL_QTY=$((TOTAL_QTY + qty))
                        ITEM_QTY["$item"]=$((${ITEM_QTY["$item"]:-0} + qty))
                        ITEM_REV["$item"]=$((${ITEM_REV["$item"]:-0} + line_total))
                    fi
                done < "$SALES_FILE"

                echo " GRAND TOTAL REVENUE : P$TOTAL_REV"
                echo " TOTAL ITEMS SOLD    : $TOTAL_QTY units"
                echo "------------------------------------------------------------------"
                echo " PRODUCT PERFORMANCE BREAKDOWN:"
                echo " ITEM NAME                              | QTY SOLD | REVENUE"
                echo "------------------------------------------------------------------"
                for item in "${!ITEM_QTY[@]}"; do
                    printf " %-38s | %8d | P%d\n" "$item" "${ITEM_QTY[$item]}" "${ITEM_REV[$item]}"
                done
            fi
            echo "=================================================================="
            read -p "Press [ENTER] to return..."
            ;;

        2)
            clear
            echo "=================================================================="
            echo "                      DETAILED SALES LOG                          "
            echo "=================================================================="
            if [ ! -s "$SALES_FILE" ]; then
                echo " [!] No sales records found."
            else
                printf "%-19s | %-9s | %-25s | %-3s | %-7s | %-10s\n" "TIMESTAMP" "ORDER ID" "ITEM" "QTY" "TOTAL" "CASHIER"
                echo "-----------------------------------------------------------------------------------"
                while IFS=',' read -r timestamp order_id item qty line_total cashier; do
                    timestamp=$(echo "$timestamp" | tr -d '\r')
                    order_id=$(echo "$order_id" | tr -d '\r')
                    item=$(echo "$item" | tr -d '\r')
                    qty=$(echo "$qty" | tr -d '\r')
                    line_total=$(echo "$line_total" | tr -d '\r')
                    cashier=$(echo "$cashier" | tr -d '\r')

                    printf "%-19s | %-9s | %-25s | %-3s | P%-6s | %-10s\n" "$timestamp" "$order_id" "$item" "$qty" "$line_total" "$cashier"
                done < "$SALES_FILE"
            fi
            echo "=================================================================="
            read -p "Press [ENTER] to return..."
            ;;

        3)
            clear
            echo "=================================================================="
            echo "                    CASHIER SALES BREAKDOWN                       "
            echo "=================================================================="
            if [ ! -s "$SALES_FILE" ]; then
                echo " [!] No sales records found."
            else
                declare -A CASHIER_REV
                declare -A CASHIER_COUNT

                while IFS=',' read -r timestamp order_id item qty line_total cashier; do
                    line_total=$(echo "$line_total" | tr -d '\r')
                    cashier=$(echo "$cashier" | tr -d '\r')

                    if [[ "$line_total" =~ ^[0-9]+$ ]]; then
                        CASHIER_REV["$cashier"]=$((${CASHIER_REV["$cashier"]:-0} + line_total))
                        CASHIER_COUNT["$cashier"]=$((${CASHIER_COUNT["$cashier"]:-0} + 1))
                    fi
                done < "$SALES_FILE"

                echo " CASHIER USERNAME      | TRANSACTIONS LOGGED | TOTAL SALES"
                echo "------------------------------------------------------------------"
                for c in "${!CASHIER_REV[@]}"; do
                    printf " %-21s | %19d | P%d\n" "$c" "${CASHIER_COUNT[$c]}" "${CASHIER_REV[$c]}"
                done
            fi
            echo "=================================================================="
            read -p "Press [ENTER] to return..."
            ;;

        4)
            clear
            echo "=================================================================="
            echo "                      CURRENT STOCK INVENTORY                     "
            echo "=================================================================="
            if [ ! -r "$STOCK_FILE" ]; then
                echo " [!] Inventory file not found."
            else
                printf " %-4s | %-32s | %-10s | %-6s | %-6s\n" "ID" "ITEM NAME" "CATEGORY" "PRICE" "STOCK"
                echo "------------------------------------------------------------------"
                while IFS=',' read -r id name cat price stock; do
                    id=$(echo "$id" | tr -d '\r')
                    name=$(echo "$name" | tr -d '\r')
                    cat=$(echo "$cat" | tr -d '\r')
                    price=$(echo "$price" | tr -d '\r')
                    stock=$(echo "$stock" | tr -d '\r')

                    if [ "$stock" -lt 10 ] 2>/dev/null; then
                        status=" [LOW STOCK]"
                    else
                        status=""
                    fi
                    printf " %-4s | %-32s | %-10s | P%-5s | %-5s%s\n" "$id" "$name" "$cat" "$price" "$stock" "$status"
                done < "$STOCK_FILE"
            fi
            echo "=================================================================="
            read -p "Press [ENTER] to return..."
            ;;

        5)
            clear
            echo "=================================================================="
            echo "                         RESTOCK ITEM                             "
            echo "=================================================================="
            read -p "Enter Product ID to Restock (e.g., 101): " TARGET_ID

            found=0
            temp_file=$(mktemp)
            while IFS=',' read -r id name cat price stock; do
                id_clean=$(echo "$id" | tr -d '\r')
                name_clean=$(echo "$name" | tr -d '\r')
                cat_clean=$(echo "$cat" | tr -d '\r')
                price_clean=$(echo "$price" | tr -d '\r')
                stock_clean=$(echo "$stock" | tr -d '\r')

                if [ "$id_clean" == "$TARGET_ID" ]; then
                    found=1
                    echo "Selected: $name_clean (Current Stock: $stock_clean)"
                    read -p "Enter additional stock units to add: " ADD_QTY
                    if [[ "$ADD_QTY" =~ ^[0-9]+$ ]]; then
                        new_stock=$((stock_clean + ADD_QTY))
                        echo "$id_clean,$name_clean,$cat_clean,$price_clean,$new_stock" >> "$temp_file"
                        echo "[SUCCESS] Updated stock for '$name_clean' to $new_stock."
                    else
                        echo "[!] Invalid number. Aborting."
                        echo "$id_clean,$name_clean,$cat_clean,$price_clean,$stock_clean" >> "$temp_file"
                    fi
                else
                    echo "$id_clean,$name_clean,$cat_clean,$price_clean,$stock_clean" >> "$temp_file"
                fi
            done < "$STOCK_FILE"

            if [ $found -eq 1 ]; then
                cp "$temp_file" "$STOCK_FILE" 2>/dev/null
                [ -f "data/inventory/stock.csv" ] && cp "$temp_file" "data/inventory/stock.csv" 2>/dev/null
            else
                echo "[!] Product ID not found."
            fi
            rm -f "$temp_file"
            sleep 1.5
            ;;

        6)
            clear
            echo "=================================================================="
            echo "                      UPDATE PRODUCT PRICE                        "
            echo "=================================================================="
            read -p "Enter Product ID to Update Price (e.g., 101): " TARGET_ID

            found=0
            temp_file=$(mktemp)
            while IFS=',' read -r id name cat price stock; do
                id_clean=$(echo "$id" | tr -d '\r')
                name_clean=$(echo "$name" | tr -d '\r')
                cat_clean=$(echo "$cat" | tr -d '\r')
                price_clean=$(echo "$price" | tr -d '\r')
                stock_clean=$(echo "$stock" | tr -d '\r')

                if [ "$id_clean" == "$TARGET_ID" ]; then
                    found=1
                    echo "Selected: $name_clean (Current Price: P$price_clean)"
                    read -p "Enter new price in Pesos: P" NEW_PRICE
                    if [[ "$NEW_PRICE" =~ ^[0-9]+$ ]]; then
                        echo "$id_clean,$name_clean,$cat_clean,$NEW_PRICE,$stock_clean" >> "$temp_file"
                        echo "[SUCCESS] Updated price for '$name_clean' to P$NEW_PRICE."
                    else
                        echo "[!] Invalid price. Aborting."
                        echo "$id_clean,$name_clean,$cat_clean,$price_clean,$stock_clean" >> "$temp_file"
                    fi
                else
                    echo "$id_clean,$name_clean,$cat_clean,$price_clean,$stock_clean" >> "$temp_file"
                fi
            done < "$STOCK_FILE"

            if [ $found -eq 1 ]; then
                cp "$temp_file" "$STOCK_FILE" 2>/dev/null
                [ -f "data/inventory/stock.csv" ] && cp "$temp_file" "data/inventory/stock.csv" 2>/dev/null
            else
                echo "[!] Product ID not found."
            fi
            rm -f "$temp_file"
            sleep 1.5
            ;;

        7)
            clear
            echo "=================================================================="
            echo "                    ADD NEW CATALOG PRODUCT                       "
            echo "=================================================================="
            read -p "Enter New Item ID (e.g. 305): " NEW_ID
            read -p "Enter Product Name          : " NEW_NAME
            echo "Categories: [1] Beverages  [2] Sinkers  [3] Meals"
            read -p "Select Category Number      : " CAT_NUM

            case "$CAT_NUM" in
                1) NEW_CAT="Beverages" ;;
                2) NEW_CAT="Sinkers" ;;
                3) NEW_CAT="Meals" ;;
                *) NEW_CAT="Beverages" ;;
            esac

            read -p "Enter Price (P)             : " NEW_PRICE
            read -p "Enter Initial Stock Units   : " NEW_STOCK

            if [[ "$NEW_PRICE" =~ ^[0-9]+$ ]] && [[ "$NEW_STOCK" =~ ^[0-9]+$ ]]; then
                echo "$NEW_ID,$NEW_NAME,$NEW_CAT,$NEW_PRICE,$NEW_STOCK" >> "$STOCK_FILE"
                [ -f "data/inventory/stock.csv" ] && echo "$NEW_ID,$NEW_NAME,$NEW_CAT,$NEW_PRICE,$NEW_STOCK" >> "data/inventory/stock.csv"
                echo -e "\n[SUCCESS] Added '$NEW_NAME' to menu catalog!"
            else
                echo -e "\n[!] Invalid price or stock values."
            fi
            sleep 1.5
            ;;

        0)
            echo "Exiting Manager Dashboard..."
            sleep 1
            break
            ;;
        *)
            echo "Invalid option."
            sleep 1
            ;;
    esac
done