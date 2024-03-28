ALTER IGNORE TABLE equipment_mac_log ADD UNIQUE(mac, port, vlan, nas_id);
