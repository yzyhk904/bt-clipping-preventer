#!/system/bin/sh

# "<point>100,$outputGain</point>" commans AudioFlinger to send audio data to bluetooth audio codec encoders
# at "$outputGain" mB (typically -320mB ~ -700mB for LDAC, and -320mB for AAC; note 100mB=1dB) output gain
# in the bit depth of an audio route to them (e.g., 32 bit for LDAC, 24 bit for aptX HD, 16 bit for AAC)
# when the absolute volume of bluetooth is enabled

if [ "$#" -gt 0 ];then
    if [ "$1" -le 0  -a  "$1" -ge -4000 ]; then
        outputGain="$1"
    else
        echo "Wrong argument: $1; out of [-4000 ~ 0]" 1>&2
        exit 1
    fi
else
    outputGain="-650"
fi

replaceText=\
"    <volume stream=\"AUDIO_STREAM_MUSIC\" deviceCategory=\"DEVICE_CATEGORY_HEADSET\">
    <!-- Modified Default Media Reference Volume Curve for bluetooth devices not to clip or distort around 0dB peaks -->
        <point>1,-5800</point>
        <point>20,-4000</point>
        <point>100,$outputGain</point>
    </volume>
"
# Mapping real "\n" to escaped characters "\\n" before executing awk for the compatibility between standard awk and Busybox's awk
awk -v replaceText="$(echo "$replaceText" | sed ':a;N;$!ba;s/\n/\\n/g')" '
    BEGIN {
        targetFound=0
    }
    targetFound==0 && $1=="<volume" && $2=="stream=\"AUDIO_STREAM_MUSIC\"" \
    && ($3=="deviceCategory=\"DEVICE_CATEGORY_HEADSET\"" \
            || $3=="deviceCategory=\"DEVICE_CATEGORY_HEADSET\">" \
            || $3=="deviceCategory=\"DEVICE_CATEGORY_HEADSET_nonEU\"" \
            || $3=="deviceCategory=\"DEVICE_CATEGORY_HEADSET_nonEU\">") {
        targetFound=1
        printf "%s", replaceText
        next
    }
    targetFound==1 && $1=="<volume" {
        targetFound=0
        print $0
        next
    }
    targetFound==1 && $1=="</volume>" {
        targetFound=0
        next
    }
    targetFound==0 {
        print $0
    }'
