#!/system/bin/sh

modDir=${0%/*/*}
if [ "${modDir%/*}" != "/data/adb/modules" ]; then
    echo "Assertion failure: wrong module path (\"${modDir}\")" 1>&2
    exit 1
fi

KeepSettingPersistent=0
if [ -e "/data/adb/magisk/magisk" ]; then
    # Under KSU and its variants, overwriting to a mounted file in a module may cause some trouble.
    # Under Magisk it's safe, so keep setting persistent.
    KeepSettingPersistent=1
fi

# "inputGain" must be specified in mB (1/100 dB)
# default value: -650 (-650mB = -6.5dB)
inputGain="-650"
if [ $# -gt 0 ];then
    inputGain="`echo \"scale=0; ( $1 * 100 ) / 1\" | bc`"
fi
if [ -z "$inputGain" ]; then
    echo "Wrong input gain ($1)"  1>&2
    exit 1
fi
echo "Input Gain: `echo \"scale=2; $inputGain / 100\" | bc` dB(FS)"

# targetFile ("audio_policy_volumes.xml") is typically or almost placed in "/vendor/etc", but tried to find the file specified when this module was installed
generatedFile="`find -L ${modDir}/system -name \"*.xml\" -print -quit`"

if [ -n "$generatedFile" ]; then
    targetFile="${generatedFile#"$modDir/system"}"
    if [ ! -r "$targetFile" ]; then
        echo "audio_policy_volumes.xml not found"  1>&2
        exit 1
    fi
elif [ -r "/vendor/etc/audio_policy_volumes.xml" ]; then
    targetFile="/vendor/etc/audio_policy_volumes.xml"
    generatedFile="{$modDir}/system$targetFile"
    mkdir -p "${generatedFile%/*}"
    touch "$generatedFile"
    echo "audio_policy_volumes.xml: $targetFile"
else
    echo "audio_policy_volumes.xml not found"  1>&2
    exit 1
fi

# Using a temporal file because "$targetFile" and "$generatedFile" may be phisically identical
tempXML="/data/local/tmp/bt-clipping-preventer_generated.xml"
# remove a previously generated file if it exists
rm "$tempXML"

sh "${modDir}/replaceVolumeEntry.sh" "$inputGain" <"$targetFile" >"$tempXML"
if [ $? -ne 0 ]; then
    echo "Modification of the volume curve failed" 1>&2
    exit 1
else
    chmod 644 "$tempXML"
    chcon u:object_r:vendor_configs_file:s0 "$tempXML"
    chown root:root "$tempXML"
fi
umount "$targetFile"
mount -o bind "$tempXML" "$targetFile"

if [ "$KeepSettingPersistent" -eq 1 ]; then
    cat "$tempXML"  >"$generatedFile"
    # The above "cat" must preserve "$generatedFile"'s context and permissions, but below commands are to make sure for root system's interference
    chmod 644 "$generatedFile"
    chcon u:object_r:vendor_configs_file:s0 "$generatedFile"
    chown root:root "$generatedFile"
fi

if [ $? -ne 0 ]; then
    echo "Copying of the modified volume curve failed"  1>&2
    exit 1
fi

# Force to reload the generated file
setprop ctl.restart audioserver
echo "Audioserver restarted for reconfiguration on the fly"

if [ "$KeepSettingPersistent" -eq 0 ]; then
    echo "(This setting change doesn't persist after rebooting because KSU and its variants may cause some trouble."
    echo " Please use Magisk if you feel inconvienience.)"
fi
