#!/system/bin/sh

maxFlag=0
if [ $# -gt 0 ];then
    case "$1" in
        "--max" )
            maxFlag=1
            ;;
        "-h" | "--help" )
            echo "Usage: ${0##*/} [--max][--help]" 1>&2
            exit 0
            ;;
        * )
            echo "wrong argument ($1)" 1>&2
            echo "Usage: ${0##*/} [--max][--help]" 1>&2
            exit 1
            ;;
    esac
fi

dumpsys media.audio_policy \
    | sed -n -e '/Volume Groups dump:/,/^Allow playback capture log:/p' \
    | sed -n -e '/-AUDIO_STREAM_MUSIC/,/^$/p' \
    | awk -v maxFlag=$maxFlag '
    $1=="DEVICE_CATEGORY_HEADSET" {
        target = $0
        maxVal=0
        while (match(target, /[(][^)]+[)]/)) {
            # Data cleaning
            data = substr(target, RSTART + 1, RLENGTH - 2)
            gsub(/^[ \t]+|[ \t]+$/, "", data)
            split(data, nums, " *, *")
            
            # Get data
            if (maxFlag==0)
                printf "%3d%%: %6.2fdB\n", nums[1], nums[2]/100
            else
                maxVal=nums[2]/100
            
            # Go to next data
            target = substr(target, RSTART + RLENGTH)
        }
        if (maxFlag==1)
            printf "%.2f\n", maxVal
        exit 0
    }'
