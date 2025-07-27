 #!/bin/bash
ORIGINAL_HEADER="/tmp/hosts_header"
NEW_ENTRIES="/tmp/hosts_new_entries"
MERGED_HOSTS="/tmp/hosts_merged"
awk '/^#/ {print; next} /^$/ {exit} {print}' /etc/hosts > "$ORIGINAL_HEADER"
cat > "$NEW_ENTRIES" << EOF
0.0.0.0         package-search.service.jetbrains.com
0.0.0.0         www.jetbrains.com
0.0.0.0         download-cdn.jetbrains.com
0.0.0.0         download.jetbrains.com
0.0.0.0         resources.jetbrains.com
0.0.0.0         schemastore.org
0.0.0.0         www.schemastore.org
0.0.0.0         jetbrains.com
0.0.0.0         cloudconfig.jetbrains.com
0.0.0.0         zendesk.com
0.0.0.0         jbssales.zendesk.com
0.0.0.0         update.jetbrains.com
0.0.0.0         update-statistics.jetbrains.com
0.0.0.0         account.jetbrains.com
0.0.0.0         oauth.account.jetbrains.com
0.0.0.0         plugins.jetbrains.com
0.0.0.0         sgtm.jetbrains.com
0.0.0.0         downloads.marketplace.jetbrains.com
0.0.0.0         analytics.services.jetbrains.com
EOF
cat "$ORIGINAL_HEADER" "$NEW_ENTRIES" > "$MERGED_HOSTS"
if sudo cp "$MERGED_HOSTS" /etc/hosts; then
    sudo chmod 644 /etc/hosts
    echo "Hosts file updated successfully."
else
    echo "Error: Failed to update /etc/hosts (check permissions or SIP)."
fi
rm -f "$ORIGINAL_HEADER" "$NEW_ENTRIES" "$MERGED_HOSTS"