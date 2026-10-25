#!/system/bin/sh

# <point>100,-320</point> commans AudioFlinger to send audio data to bluetooth audio codec encoders at -3.2dB (-320mB) output gain
# in the bit depth of an audio route to them (e.g., 32bit for LDAC, 24bit for aptX HD, 16bit for AAC) when the absolute volume of blluetooth is enabled

replaceText=\
"    <volume stream=\"AUDIO_STREAM_MUSIC\" deviceCategory=\"DEVICE_CATEGORY_HEADSET\">
    <!-- Modified Default Media Reference Volume Curve for bluetooth devices not to clip or distort around 0dB peaks -->
        <point>1,-5800<\/point>
        <point>20,-4000<\/point>
        <point>60,-1700<\/point>
        <point>100,-320<\/point>
    <\/volume>
"

awk -v replaceText="$replaceText" '
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
    targetFound==1 && $1=="<\/volume>" {
        targetFound=0
        next
    }
    targetFound==0 {
        print $0
    }'
