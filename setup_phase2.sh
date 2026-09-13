#!/bin/bash
set -e

echo "[1/4] Creating clean directory skeleton under /srv/grainsmart..."
sudo rm -rf /srv/grainsmart /srv/grainsmart_cafe
sudo mkdir -p /srv/grainsmart/{orders,kitchen/archive,inventory,finance}

echo "[2/4] Initializing CSV databases..."
cat << 'CSVO' | sudo tee /srv/grainsmart/inventory/stock.csv > /dev/null
ItemID,ItemName,Category,Price,Stock
101,Barley Matcha,Drinks,110,50
102,Spanish Latte,Drinks,110,40
103,Garlic Parmesan Wings,Kitchen,175,25
104,Waffles (Plain),Kitchen,90,30
CSVO

cat << 'CSVO' | sudo tee /srv/grainsmart/orders/sales.csv > /dev/null
Timestamp,OrderID,ItemName,Qty,Total,Cashier
2026-09-12 08:30:00,ORD-1001,Barley Matcha,2,220,cash_cruz
CSVO

cat << 'CSVO' | sudo tee /srv/grainsmart/finance/closings.csv > /dev/null
Date,OpeningCash,TotalSales,EndingCash,Status
2026-09-11,5000,12450,17450,CLOSED
CSVO

echo "[3/4] Creating 2 team groups and 3 staff accounts..."
sudo groupadd -f pos_team
sudo groupadd -f kitchen_team

for u in mgr_santos cash_cruz cook_reyes; do
    if ! id -u "$u" &>/dev/null; then
        sudo useradd -m -s /bin/bash "$u"
        echo "$u:password123" | sudo chpasswd
    fi
done

sudo usermod -aG pos_team cash_cruz
sudo usermod -aG kitchen_team cook_reyes
sudo usermod -aG pos_team,kitchen_team,sudo mgr_santos

echo "[4/4] Setting folder ownership & permissions..."
sudo chown -R mgr_santos:pos_team /srv/grainsmart/orders
sudo chmod 2770 /srv/grainsmart/orders

sudo chown -R mgr_santos:kitchen_team /srv/grainsmart/kitchen
sudo chmod 2770 /srv/grainsmart/kitchen

sudo chown -R mgr_santos:mgr_santos /srv/grainsmart/inventory
sudo chmod 700 /srv/grainsmart/inventory

sudo chown -R mgr_santos:mgr_santos /srv/grainsmart/finance
sudo chmod 700 /srv/grainsmart/finance

mkdir -p data/inventory data/orders data/finance
cp /srv/grainsmart/inventory/stock.csv data/inventory/
cp /srv/grainsmart/orders/sales.csv data/orders/
cp /srv/grainsmart/finance/closings.csv data/finance/

echo "=== GRAINSMART SYSTEM SETUP COMPLETE ==="
tree /srv/grainsmart