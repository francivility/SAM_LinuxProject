#!/bin/bash
# ==============================================================================
# GRAINSMART CAFE - FULLY ALIGNED POS TUI
# - Fixes background color leakage inside dialog boxes.
# - Integrates Quantity Input prompt directly inside the modal frame.
# - Full Dark Green background with centered solid black dialogs.
# ==============================================================================

ORDERS_DIR="/srv/grainsmart_cafe/orders"
KITCHEN_DIR="/srv/grainsmart_cafe/kitchen"
STOCK_FILE="/srv/grainsmart_cafe/inventory/stock.txt"
SALES_LOG="/srv/grainsmart_cafe/orders/sales.log"

mkdir -p "$ORDERS_DIR" "$KITCHEN_DIR" "$(dirname "$STOCK_FILE")"

# Colors
BG_DARK_GREEN='\033[48;5;22m'  # Forest Green Outer Fill
BOX_BG='\033[40m'              # Solid Black Window Box
BORDER_FG='\033[1;32m'         # Bright Green Borders
TITLE_FG='\033[1;33m'          # Yellow Title Text
TEXT_FG='\033[1;37m'           # White Option Text
HIGHLIGHT='\033[30;43m\033[1m' # Yellow Highlight Bar with Black Text
RESET='\033[0m'

cleanup() {
    printf "\033[?1049l\033[?25h"
    clear
}
trap cleanup EXIT

# Enter Alternate Screen Buffer (Prevents scrolling/stacking)
printf "\033[?1049h"

custom_menu() {
    local title="$1"
    shift
    local options=("$@")
    local selected=0
    local total=${#options[@]}

    local max_len=${#title}
    for opt in "${options[@]}"; do
        [ ${#opt} -gt $max_len ] && max_len=${#opt}
    done
    local box_width=$((max_len + 8))
    [ $box_width -lt 58 ] && box_width=58

    printf "\033[?25l"

    while true; do
        local lines=$(tput lines)
        local cols=$(tput cols)
        
        local start_row=$(( (lines - total - 5) / 2 + 1 ))
        [ $start_row -lt 1 ] && start_row=1
        local start_col=$(( (cols - box_width) / 2 + 1 ))
        [ $start_col -lt 1 ] && start_col=1

        local buf="\033[H${BG_DARK_GREEN}"

        for ((r=1; r<=lines; r++)); do
            buf+=$(printf "\033[%d;1H\033[K" "$r")
        done

        # Top Border
        buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}┌" "$start_row" "$start_col")
        for ((i=0; i<box_width-2; i++)); do buf+="─"; done
        buf+="┐${RESET}"

        # Title
        local pad_title=$(( (box_width - 2 - ${#title}) / 2 ))
        buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}│${BOX_BG}%*s${TITLE_FG}%s${BOX_BG}%*s${BORDER_FG}│${RESET}" \
            $((start_row + 1)) "$start_col" $pad_title "" "$title" $((box_width - 2 - pad_title - ${#title})) "")

        # Separator
        buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}├" $((start_row + 2)) "$start_col")
        for ((i=0; i<box_width-2; i++)); do buf+="─"; done
        buf+="┤${RESET}"

        # Options
        for ((i=0; i<total; i++)); do
            local item="${options[$i]}"
            local pad=$((box_width - 4 - ${#item}))
            if [ $i -eq $selected ]; then
                buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}│ ${HIGHLIGHT}%s%*s${RESET} ${BORDER_FG}${BOX_BG}│${RESET}" \
                    $((start_row + 3 + i)) "$start_col" "$item" $pad "")
            else
                buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}│ ${TEXT_FG}%s%*s${RESET} ${BORDER_FG}${BOX_BG}│${RESET}" \
                    $((start_row + 3 + i)) "$start_col" "$item" $pad "")
            fi
        done

        # Bottom Border
        buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}└" $((start_row + 3 + total)) "$start_col")
        for ((i=0; i<box_width-2; i++)); do buf+="─"; done
        buf+="┘${RESET}"

        printf "%b" "$buf"

        read -rsn1 key
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 -t 0.01 rest
            key="$key$rest"
            if [[ $key == $'\x1b[A' ]]; then
                ((selected--))
                [ $selected -lt 0 ] && selected=$((total - 1))
            elif [[ $key == $'\x1b[B' ]]; then
                ((selected++))
                [ $selected -ge $total ] && selected=0
            fi
        elif [[ $key == "" ]]; then
            printf "\033[?25h"
            return $selected
        fi
    done
}

process_order() {
    local ITEM="$1"
    local PRICE="$2"
    local TYPE="$3"

    local lines=$(tput lines)
    local cols=$(tput cols)
    local box_width=62
    local start_col=$(( (cols - box_width) / 2 + 1 ))
    [ $start_col -lt 1 ] && start_col=1
    local start_row=$(( (lines - 9) / 2 + 1 ))
    [ $start_row -lt 1 ] && start_row=1

    # Paint Full Background
    local buf="\033[H${BG_DARK_GREEN}"
    for ((r=1; r<=lines; r++)); do buf+=$(printf "\033[%d;1H\033[K" "$r"); done

    local title="QUANTITY SELECTION"
    local pad_title=$(( (box_width - 2 - ${#title}) / 2 ))

    # Top Border
    buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}┌" "$start_row" "$start_col")
    for ((i=0; i<box_width-2; i++)); do buf+="─"; done
    buf+="┐${RESET}"

    # Title Line
    buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}│${BOX_BG}%*s${TITLE_FG}%s${BOX_BG}%*s${BORDER_FG}│${RESET}" \
        $((start_row + 1)) "$start_col" $pad_title "" "$title" $((box_width - 2 - pad_title - ${#title})) "")

    # Separator
    buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}├" $((start_row + 2)) "$start_col")
    for ((i=0; i<box_width-2; i++)); do buf+="─"; done
    buf+="┤${RESET}"

    # Item Line
    local str1="Selected Item : $ITEM"
    local pad1=$((box_width - 4 - ${#str1}))
    buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}│ ${TEXT_FG}Selected Item : ${TITLE_FG}%s${BOX_BG}%*s ${BORDER_FG}│${RESET}" \
        $((start_row + 3)) "$start_col" "$ITEM" $pad1 "")

    # Price Line
    local str2="Unit Price    : PHP $PRICE"
    local pad2=$((box_width - 4 - ${#str2}))
    buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}│ ${TEXT_FG}Unit Price    : PHP ${TITLE_FG}%s${BOX_BG}%*s ${BORDER_FG}│${RESET}" \
        $((start_row + 4)) "$start_col" "$PRICE" $pad2 "")

    # Blank Line
    buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}│${BOX_BG}%*s${BORDER_FG}│${RESET}" \
        $((start_row + 5)) "$start_col" $((box_width - 2)) "")

    # Prompt Line
    local prompt_text="Enter Quantity [Default 1]: "
    local pad4=$((box_width - 4 - ${#prompt_text}))
    buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}│ ${TITLE_FG}%s${BOX_BG}%*s ${BORDER_FG}│${RESET}" \
        $((start_row + 6)) "$start_col" "$prompt_text" $pad4 "")

    # Bottom Border
    buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}└" $((start_row + 7)) "$start_col")
    for ((i=0; i<box_width-2; i++)); do buf+="─"; done
    buf+="┘${RESET}"

    printf "%b" "$buf"

    # Position Cursor Inside Prompt Field
    local input_col=$((start_col + 2 + ${#prompt_text}))
    local input_row=$((start_row + 6))
    
    printf "\033[?25h" # Show cursor
    tput cup $((input_row - 1)) $((input_col - 1))
    
    printf "${TITLE_FG}${BOX_BG}"
    read QTY
    printf "${RESET}"
    QTY=${QTY:-1}

    if ! [[ "$QTY" =~ ^[0-9]+$ ]] || [ "$QTY" -le 0 ]; then
        return
    fi

    TOTAL=$((PRICE * QTY))
    ORDER_ID="ORD-$(date +%H%M%S)"
    TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

    if ! grep -q "^$ITEM," "$STOCK_FILE" 2>/dev/null; then
        echo "$ITEM,50" >> "$STOCK_FILE"
    fi

    echo "$TIMESTAMP | $ORDER_ID | $ITEM | Qty: $QTY | Total: PHP $TOTAL" >> "$SALES_LOG"

    CURRENT_QTY=$(grep "^$ITEM," "$STOCK_FILE" | cut -d',' -f2)
    NEW_QTY=$((CURRENT_QTY - QTY))
    sed -i "s/^$ITEM,.*/$ITEM,$NEW_QTY/" "$STOCK_FILE"

    # Status Text
    local status_text=""
    if [ "$TYPE" == "KITCHEN" ]; then
        TICKET_FILE="$KITCHEN_DIR/ticket_${ORDER_ID}.txt"
        {
            echo "===================================="
            echo "         GRAINSMART CAFE"
            echo "       KITCHEN ORDER TICKET"
            echo "===================================="
            echo "Order ID : $ORDER_ID"
            echo "Time     : $TIMESTAMP"
            echo "Item     : $ITEM"
            echo "Quantity : $QTY"
            echo "===================================="
        } > "$TICKET_FILE"
        chmod 666 "$TICKET_FILE"
        status_text="Ticket routed to KITCHEN"
    else
        status_text="Drink order complete"
    fi

    # Render Receipt Box
    buf="\033[H${BG_DARK_GREEN}"
    for ((r=1; r<=lines; r++)); do buf+=$(printf "\033[%d;1H\033[K" "$r"); done

    title="TRANSACTION RECEIPT"
    pad_title=$(( (box_width - 2 - ${#title}) / 2 ))

    # Top Border
    buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}┌" "$start_row" "$start_col")
    for ((i=0; i<box_width-2; i++)); do buf+="─"; done
    buf+="┐${RESET}"

    # Title
    buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}│${BOX_BG}%*s${TITLE_FG}%s${BOX_BG}%*s${BORDER_FG}│${RESET}" \
        $((start_row + 1)) "$start_col" $pad_title "" "$title" $((box_width - 2 - pad_title - ${#title})) "")

    # Separator
    buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}├" $((start_row + 2)) "$start_col")
    for ((i=0; i<box_width-2; i++)); do buf+="─"; done
    buf+="┤${RESET}"

    local rlines=(
        "Order ID : $ORDER_ID"
        "Time     : $TIMESTAMP"
        "Item     : $ITEM"
        "Quantity : $QTY"
        "Total    : PHP $TOTAL"
        "Status   : $status_text"
    )

    for ((i=0; i<${#rlines[@]}; i++)); do
        local line="${rlines[$i]}"
        local pad=$((box_width - 4 - ${#line}))
        buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}│ ${TEXT_FG}%s${BOX_BG}%*s ${BORDER_FG}│${RESET}" \
            $((start_row + 3 + i)) "$start_col" "$line" $pad "")
    done

    # Blank Line
    buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}│${BOX_BG}%*s${BORDER_FG}│${RESET}" \
        $((start_row + 3 + ${#rlines[@]})) "$start_col" $((box_width - 2)) "")

    # Enter Prompt
    local enter_prompt="Press [ENTER] to return to menu..."
    local epad=$((box_width - 4 - ${#enter_prompt}))
    buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}│ ${TITLE_FG}%s${BOX_BG}%*s ${BORDER_FG}│${RESET}" \
        $((start_row + 4 + ${#rlines[@]})) "$start_col" "$enter_prompt" $epad "")

    # Bottom Border
    buf+=$(printf "\033[%d;%dH${BORDER_FG}${BOX_BG}└" $((start_row + 5 + ${#rlines[@]})) "$start_col")
    for ((i=0; i<box_width-2; i++)); do buf+="─"; done
    buf+="┘${RESET}"

    printf "%b" "$buf"
    printf "\033[?25l"

    read -rsn1
}

while true; do
    custom_menu "GRAINSMART CAFE - POS TERMINAL" \
        "Signature & Hot Drinks" \
        "Iced Beverages & Frappes" \
        "Milk Teas & Fruit Juices" \
        "Snacks & Light Bites (Kitchen)" \
        "Rice Meals & Wings (Kitchen)" \
        "Exit POS System"
    
    MAIN_CHOICE=$?

    case $MAIN_CHOICE in
        0)
            while true; do
                custom_menu "SIGNATURE & HOT DRINKS" \
                    "Cafe Filipino (Signature Black Rice Coffee)  - PHP 95" \
                    "Barley Matcha                                - PHP 110" \
                    "Sweet Ube (With Pineapple & Coconut Milk)    - PHP 115" \
                    "Nectar Juice                                 - PHP 90" \
                    "Spanish Latte                                - PHP 110" \
                    "Cafe Mocha                                   - PHP 115" \
                    "Caramel Macchiato                            - PHP 120" \
                    "Hot Choco                                    - PHP 95" \
                    "Freshly Brewed Black Rice Coffee             - PHP 85" \
                    "Back to Main Menu"
                
                SUB_CHOICE=$?
                case $SUB_CHOICE in
                    0) process_order "Cafe Filipino (Black Rice Coffee)" 95 "DRINK" ;;
                    1) process_order "Barley Matcha" 110 "DRINK" ;;
                    2) process_order "Sweet Ube" 115 "DRINK" ;;
                    3) process_order "Nectar Juice" 90 "DRINK" ;;
                    4) process_order "Spanish Latte" 110 "DRINK" ;;
                    5) process_order "Cafe Mocha" 115 "DRINK" ;;
                    6) process_order "Caramel Macchiato" 120 "DRINK" ;;
                    7) process_order "Hot Choco" 95 "DRINK" ;;
                    8) process_order "Freshly Brewed Black Rice Coffee" 85 "DRINK" ;;
                    9) break ;;
                esac
            done
            ;;

        1)
            while true; do
                custom_menu "ICED BEVERAGES & FRAPPES" \
                    "Iced Cafe Latte                            - PHP 115" \
                    "Iced Mocha                                 - PHP 125" \
                    "Iced Cafe Caramel                          - PHP 125" \
                    "Iced Choco                                 - PHP 110" \
                    "Barley Matcha Frappe                       - PHP 145" \
                    "Java Chip Frappe                           - PHP 140" \
                    "Cookies & Cream Frappe                     - PHP 140" \
                    "Cheesecake Frappe                          - PHP 145" \
                    "Strawberry Frappe                          - PHP 140" \
                    "Taro Frappe                                - PHP 135" \
                    "Back to Main Menu"
                
                SUB_CHOICE=$?
                case $SUB_CHOICE in
                    0) process_order "Iced Cafe Latte" 115 "DRINK" ;;
                    1) process_order "Iced Mocha" 125 "DRINK" ;;
                    2) process_order "Iced Cafe Caramel" 125 "DRINK" ;;
                    3) process_order "Iced Choco" 110 "DRINK" ;;
                    4) process_order "Barley Matcha Frappe" 145 "DRINK" ;;
                    5) process_order "Java Chip Frappe" 140 "DRINK" ;;
                    6) process_order "Cookies & Cream Frappe" 140 "DRINK" ;;
                    7) process_order "Cheesecake Frappe" 145 "DRINK" ;;
                    8) process_order "Strawberry Frappe" 140 "DRINK" ;;
                    9) process_order "Taro Frappe" 135 "DRINK" ;;
                    10) break ;;
                esac
            done
            ;;

        2)
            while true; do
                custom_menu "MILK TEAS & FRUIT JUICES" \
                    "Okinawa Milk Tea                           - PHP 115" \
                    "Cheesecake Milk Tea                        - PHP 125" \
                    "Nutella Milk Tea                           - PHP 125" \
                    "Matcha Milk Tea                            - PHP 120" \
                    "Caramel Milk Tea                           - PHP 115" \
                    "Wintermelon Milk Tea                       - PHP 110" \
                    "Honey Peach Mango Juice                    - PHP 110" \
                    "Passion Fruit Lychee Juice                 - PHP 110" \
                    "Green Apple Kiwi Juice                     - PHP 110" \
                    "Berry Melon Juice                         - PHP 110" \
                    "Back to Main Menu"
                
                SUB_CHOICE=$?
                case $SUB_CHOICE in
                    0) process_order "Okinawa Milk Tea" 115 "DRINK" ;;
                    1) process_order "Cheesecake Milk Tea" 125 "DRINK" ;;
                    2) process_order "Nutella Milk Tea" 125 "DRINK" ;;
                    3) process_order "Matcha Milk Tea" 120 "DRINK" ;;
                    4) process_order "Caramel Milk Tea" 115 "DRINK" ;;
                    5) process_order "Wintermelon Milk Tea" 110 "DRINK" ;;
                    6) process_order "Honey Peach Mango Juice" 110 "DRINK" ;;
                    7) process_order "Passion Fruit Lychee Juice" 110 "DRINK" ;;
                    8) process_order "Green Apple Kiwi Juice" 110 "DRINK" ;;
                    9) process_order "Berry Melon Juice" 110 "DRINK" ;;
                    10) break ;;
                esac
            done
            ;;

        3)
            while true; do
                custom_menu "SNACKS & LIGHT BITES" \
                    "Waffles (Plain)                            - PHP 90" \
                    "Waffles (Oreo/Caramel/Blueberry/Strawberry)- PHP 110" \
                    "Pancakes (Plain)                           - PHP 85" \
                    "Pancakes (Oreo/Caramel/Blueberry/Strawberry)- PHP 105" \
                    "French Fries (Regular)                     - PHP 80" \
                    "French Fries (Cheese/BBQ/Sour Cream)     - PHP 95" \
                    "Nachos (Regular)                           - PHP 120" \
                    "Nachos (Premium Cheese & Meat)             - PHP 150" \
                    "Back to Main Menu"
                
                SUB_CHOICE=$?
                case $SUB_CHOICE in
                    0) process_order "Waffles (Plain)" 90 "KITCHEN" ;;
                    1) process_order "Waffles (Flavored)" 110 "KITCHEN" ;;
                    2) process_order "Pancakes (Plain)" 85 "KITCHEN" ;;
                    3) process_order "Pancakes (Flavored)" 105 "KITCHEN" ;;
                    4) process_order "French Fries (Regular)" 80 "KITCHEN" ;;
                    5) process_order "French Fries (Flavored)" 95 "KITCHEN" ;;
                    6) process_order "Nachos (Regular)" 120 "KITCHEN" ;;
                    7) process_order "Nachos (Premium Cheese & Meat)" 150 "KITCHEN" ;;
                    8) break ;;
                esac
            done
            ;;

        4)
            while true; do
                custom_menu "RICE MEALS & WINGS" \
                    "Garlic Parmesan Wings with Rice            - PHP 175" \
                    "Buffalo Chicken Wings with Rice            - PHP 175" \
                    "Soy Garlic Chicken Wings with Rice         - PHP 175" \
                    "Back to Main Menu"
                
                SUB_CHOICE=$?
                case $SUB_CHOICE in
                    0) process_order "Garlic Parmesan Wings with Rice" 175 "KITCHEN" ;;
                    1) process_order "Buffalo Chicken Wings with Rice" 175 "KITCHEN" ;;
                    2) process_order "Soy Garlic Wings with Rice" 175 "KITCHEN" ;;
                    3) break ;;
                esac
            done
            ;;

        5)
            exit 0
            ;;
    esac
done