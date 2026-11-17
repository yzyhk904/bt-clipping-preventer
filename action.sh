#!/system/bin/sh

echo "Please install WebUI X: Portable (com.dergoogler.mmrl.wx),"
echo "and use WebUI setting menu of this module in the app!"
exit 1

# Don't work below by unknown reasons till now
MODDIR="${0%/*}"

# Extract the module ID dynamically from module.prop
MOD_ID=$(grep -m1 '^id=' "$MODDIR/module.prop" | cut -d'=' -f2 | tr -d '\r')

# Fallback if module.prop parsing fails
[ -z "$MOD_ID" ] && MOD_ID="bt-clipping-preventer"

if pm path com.dergoogler.mmrl.wx >/dev/null 2>&1; then
    echo "- Launching WebUI in WebUI X: Portable..."
    am start -n "com.dergoogler.mmrl.wx/.ui.activity.webui.WebUIActivity" \
        -e MOD_ID "$MOD_ID" >/dev/null 2>&1
else
    echo "! No WebUI host app found."
    echo "! Please install WebUI X: Portable (com.dergoogler.mmrl.wx)."
    exit 1
fi
