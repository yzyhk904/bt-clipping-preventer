#!/system/bin/sh

# "audio_policy_volumes.xml" is typically or almost placed in "/vendor/etc"
targetFile="/vendor/etc/audio_policy_volumes.xml"

# Set "outputGain" (output gain when the absolume volume of bluetooth is used); 
#   typically -620 mB (-6.2 dB) for LDAC and -320 mB (-3.2 dB) for AAC not to saturate (or bypass a peak limiter) and clip
outputGain="-620"

#

generatedFile="$MODPATH/system$targetFile"

if [ -r "$targetFile" ]; then
    mkdir -p "${generatedFile%/*}"
    touch "$generatedFile"
    sh "$MODPATH/replaceVolumeEntry.sh" "$outputGain" <"$targetFile" >"$generatedFile"
    chmod 644 "$generatedFile"
    chcon u:object_r:vendor_configs_file:s0 "$generatedFile"
    chown root:root "$generatedFile"
    chmod -R a+rX "${generatedFile%/*}"
else
    abort "\"$targetFile\" not found"
fi
rm -f "$MODPATH/LICENSE" "$MODPATH/README.md" "$MODPATH/changelog.md" "$MODPATH/replaceVolumeEntry.sh"

outputGain=`echo "scale=2; $outputGain / 100" | bc`
ui_print "- Replace target file: $targetFile"
ui_print "- Output gain (for BT abs. vol.): $outputGain dB"
