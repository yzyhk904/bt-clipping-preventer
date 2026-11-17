#!/system/bin/sh

# "audio_policy_volumes.xml" is typically or almost placed in "/vendor/etc"
targetFile="/vendor/etc/audio_policy_volumes.xml"

# Set "inputGain" (input gain of BT codecs when the absolume volume of bluetooth is used); 
#   typically -320mB ~ -600mB (i.e., -3.2dB ~ -6.0dB) for LDAC and -320mB (-3.2dB) for AAC not to saturate in decodeing process (DRC, band merging, etc.),
#   must be geater than or equal to -1700mB(-17dB)
inputGain="-580"

#

if [ "$inputGain" -lt -1700 ]; then
    abort "Input gain of BT codecs must be greater than or equal to -17dB"
fi
generatedFile="$MODPATH/system$targetFile"

if [ -r "$targetFile" ]; then
    mkdir -p "${generatedFile%/*}"
    touch "$generatedFile"
    sh "$MODPATH/replaceVolumeEntry.sh" "$inputGain" <"$targetFile" >"$generatedFile"
    chmod 644 "$generatedFile"
    chcon u:object_r:vendor_configs_file:s0 "$generatedFile"
    chown root:root "$generatedFile"
    chmod -R a+rX "${generatedFile%/*}"
else
    abort "\"$targetFile\" not found"
fi
rm -f "$MODPATH/LICENSE" "$MODPATH/README.md" "$MODPATH/changelog.md"

inputGain=`echo "scale=2; $inputGain / 100" | bc`
ui_print "- Replace target file: $targetFile"
ui_print "- Input gain (for BT absvol): $inputGain dB"
