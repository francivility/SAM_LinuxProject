#!/usr/bin/env bash

DB_FILE="gym_members.csv"

# Create database with headers if missing
if [ ! -f "$DB_FILE" ]; then
    echo "Member_ID,Full_Name,Phone,Email,Emergency_Contact,Plan,Join_Date" > "$DB_FILE"
fi

show_menu() {
    clear
    echo "=================================================="
    echo "        POWERHOUSE GYM MANAGEMENT SYSTEM          "
    echo "=================================================="
    echo "1. Register New Member"
    echo "2. View All Registered Members"
    echo "3. Search Member (by Name or ID)"
    echo "4. Check Total Member Count"
    echo "5. Exit System"
    echo "=================================================="
}

register_member() {
    echo ""
    echo "--- NEW MEMBER REGISTRATION ---"
    read -p "Full Name: " FULL_NAME
    read -p "Phone Number: " PHONE
    read -p "Email Address: " EMAIL
    read -p "Emergency Contact (Name & Phone): " EMERGENCY

    echo ""
    echo "Select Membership Plan:"
    echo "  [1] Basic   - \$30/mo (Gym Floor & Lockers)"
    echo "  [2] Premium - \$50/mo (Basic + Group Classes & Sauna)"
    echo "  [3] VIP     - \$80/mo (Premium + 24/7 Access & PT Session)"
    read -p "Choice (1-3): " PLAN_CHOICE

    case "$PLAN_CHOICE" in
        1) PLAN="Basic (\$30/mo)" ;;
        2) PLAN="Premium (\$50/mo)" ;;
        3) PLAN="VIP (\$80/mo)" ;;
        *) PLAN="Basic (\$30/mo)" ;;
    esac

    MEMBER_ID="MEM-$((10000 + RANDOM % 90000))"
    JOIN_DATE=$(date "+%Y-%m-%d %H:%M:%S")

    echo "\"$MEMBER_ID\",\"$FULL_NAME\",\"$PHONE\",\"$EMAIL\",\"$EMERGENCY\",\"$PLAN\",\"$JOIN_DATE\"" >> "$DB_FILE"

    echo ""
    echo "[✓] Member Registered Successfully!"
    echo "--------------------------------------------------"
    echo " Assigned Member ID: $MEMBER_ID"
    echo " Full Name:          $FULL_NAME"
    echo " Plan Selected:      $PLAN"
    echo " Database File:      $DB_FILE"
    echo "--------------------------------------------------"
    read -p "Press Enter to return to main menu..."
}

view_members() {
    echo ""
    echo "--- REGISTERED GYM MEMBERS ---"
    if [ $(wc -l < "$DB_FILE") -le 1 ]; then
        echo "[!] No members registered in the system yet."
    else
        column -s, -t < "$DB_FILE" | tr -d '"'
    fi
    echo ""
    read -p "Press Enter to return to main menu..."
}

search_member() {
    echo ""
    echo "--- SEARCH MEMBER RECORD ---"
    read -p "Enter Name or Member ID to search: " QUERY
    if [ -z "$QUERY" ]; then
        echo "[!] Search query cannot be empty."
    else
        echo ""
        echo "Search Results:"
        echo "--------------------------------------------------"
        RESULTS=$(grep -i "$QUERY" "$DB_FILE")
        if [ -n "$RESULTS" ]; then
            echo "$RESULTS" | tr -d '"'
        else
            echo "[!] No matching member records found for '$QUERY'."
        fi
        echo "--------------------------------------------------"
    fi
    echo ""
    read -p "Press Enter to return to main menu..."
}

count_members() {
    echo ""
    TOTAL=$(($(wc -l < "$DB_FILE") - 1))
    if [ $TOTAL -lt 0 ]; then TOTAL=0; fi
    echo "--------------------------------------------------"
    echo " Total Active Members Registered: $TOTAL"
    echo "--------------------------------------------------"
    echo ""
    read -p "Press Enter to return to main menu..."
}

while true; do
    show_menu
    read -p "Select an option (1-5): " CHOICE
    case "$CHOICE" in
        1) register_member ;;
        2) view_members ;;
        3) search_member ;;
        4) count_members ;;
        5) echo -e "\nExiting Gym System. Goodbye!\n"; exit 0 ;;
        *) echo "[!] Invalid choice. Please select 1-5."; sleep 1 ;;
    esac
done
