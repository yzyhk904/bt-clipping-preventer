#!/system/bin/sh

targetFile="/vendor/etc/audio_policy_volumes.xml"
generatedFile="$MODPATH/system$targetFile"

if [ -r "$targetFile" ]; then
    mkdir -p "${generatedFile%/*}"
    touch "$generatedFile"
    sh "$MODPATH/replaceVolumeEntry.sh" <"$targetFile" >"$generatedFile"
    chmod 644 "$generatedFile"
    chcon u:object_r:vendor_configs_file:s0 "$generatedFile"
    chown root:root "$generatedFile"
    chmod -R a+rX "${generatedFile%/*}"
else
    abort "\"$targetFile\" not found"
fi
rm -f "$MODPATH/LICENSE" "$MODPATH/README.md" "$MODPATH/changelog.md" "$MODPATH/replaceVolumeEntry.sh"
ui_print "- Replace target file: $targetFile"
