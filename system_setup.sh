#!/bin/bash
# ==============================================================================
# STEP 1: SYSTEM FOUNDATION BUILD
# - Folders: Creates /srv/grainsmart_cafe/ subdirectories (orders, kitchen, inventory, reports)[cite: 1].
# - Security: Sets up role groups/accounts & enforces SGID 2770 + ACL permissions[cite: 1].
# - Seed Data: Preloads starting stock levels and creates the sales log file[cite: 1].
# ==============================================================================

set -e

echo "1. Creating directory structure..."
sudo mkdir -p /srv/grainsmart_cafe/{orders,kitchen,inventory,reports}

echo "2. Creating functional groups..."
sudo groupadd managers 2>/dev/null || true
sudo groupadd cashiers 2>/dev/null || true
sudo groupadd baristas 2>/dev/null || true
sudo groupadd cooks 2>/dev/null || true

echo "3. Provisioning staff accounts..."
sudo useradd -m -g managers -G sudo -s /bin/bash mgr_owner1 2>/dev/null || true
sudo useradd -m -g cashiers -G baristas -s /bin/bash csh_staff1 2>/dev/null || true
sudo useradd -m -g baristas -G cashiers -s /bin/bash bar_staff1 2>/dev/null || true
sudo useradd -m -g cooks -s /bin/bash cuk_staff1 2>/dev/null || true

echo "4. Setting folder ownership and permissions..."
sudo chown -R mgr_owner1:managers /srv/grainsmart_cafe/
sudo chown mgr_owner1:cashiers /srv/grainsmart_cafe/orders
sudo chown mgr_owner1:cooks /srv/grainsmart_cafe/kitchen

sudo chmod 2770 /srv/grainsmart_cafe/orders
sudo chmod 2770 /srv/grainsmart_cafe/kitchen
sudo chmod 2770 /srv/grainsmart_cafe/inventory
sudo chmod 2700 /srv/grainsmart_cafe/reports

echo "5. Setting ACL rules..."
sudo setfacl -m g:cashiers:rwx /srv/grainsmart_cafe/kitchen
sudo setfacl -d -m g:cashiers:rwx /srv/grainsmart_cafe/kitchen
sudo setfacl -m g:cashiers:rwx /srv/grainsmart_cafe/inventory
sudo setfacl -m g:baristas:rwx /srv/grainsmart_cafe/inventory
sudo setfacl -m g:cooks:rwx /srv/grainsmart_cafe/inventory

echo "6. Initializing inventory and sales log..."
sudo bash -c 'cat << STOCK > /srv/grainsmart_cafe/inventory/stock.txt
Rice Coffee,50
Taro Frappe,30
Caramel Macchiato,30
Rice Meal - Pork Liempo,25
Rice Meal - Beef Tapa,25
Sandwich - Clubhead,20
STOCK'

sudo touch /srv/grainsmart_cafe/orders/sales.log
sudo chmod 666 /srv/grainsmart_cafe/inventory/stock.txt
sudo chmod 666 /srv/grainsmart_cafe/orders/sales.log

echo "=========================================="
echo "SUCCESS: Foundation built successfully!"
echo "=========================================="