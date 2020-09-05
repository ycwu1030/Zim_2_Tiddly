#!/bin/bash

convert_single_file () {
    # The 1st argument is the tid file (with the full path)
    # The 2nd argument is the md file
    file_no_dir=${2##*/}
    file_path_no_root=${2#*/}
    file_path=$(dirname "$file_path_no_root" | sed 's#/#:#g') # First replace / by : (we will replace back to )
    file_no_ext=${file_no_dir%.md}
    file_leading_dir=$(echo "$file_path_no_root" | awk -F'/' '{print $1}')


    # The body
    # Strike no need
    # Horizontal line no need
    # verbatim no need
    # Code block no need
    sed -e '/^created: /d' \
    -e '/^modified: /d' \
    -e '/^title: /d' \
    -e '/^tmap\.id: /d' \
    -e '/^type: /d' \
    -e '/^caption: /d' \
    -e '/^tags: /d' \
    -e 's/^\* /- /g' \
    -e 's/^\*\{2\} /    - /g' \
    -e 's/^\*\{3\} /        - /g' \
    -e 's/^\*\{4\} /            - /g' \
    -e 's/^\*\{5\} /                - /g' \
    -e 's/^\*\{6\} /                    - /g' \
    -e 's/^# /1. /g' \
    -e 's/^#\{2\} /    1. /g' \
    -e 's/^#\{3\} /        1. /g' \
    -e 's/^#\{4\} /            1. /g' \
    -e 's/^#\{5\} /                1. /g' \
    -e 's/^! \(.*\)/# \1/g' \
    -e 's/^!! \(.*\)/## \1/g' \
    -e 's/^!!! \(.*\)/### \1/g' \
    -e 's/^!!!! \(.*\)/#### \1/g' \
    -e 's/^!!!!! \(.*\)/##### \1/g' \
    -e 's/^!!!!!! \(.*\)/###### \1/g' `# Headings` \
    -e "s/\'\'\([^\']*\)\'\'/\*\*\1\*\*/g" `# bold` \
    -e "s#//\([^/]*\)//#\*\1\*#g" `# italics` \
    -e "s#__\([^_]*\)__#\*\*_\1_\*\*#g" `# underscores` \
    -e "s/\[\[\([^|]*\)|\([^|]*\)\]\]/\[\[\2|\1\]\]/g" \
    "$1" | \
    sed -e "s/\[img.*\[\(.*\)\]\]/!\[\[\1\]\]/g" `# Plots (remember to convert tiff to png)` \
    >> "$2"
    

}


get_mili_sec () {
    # Since, in mac, date does not support +%N to get finer time stamp, so this is a work around
    militime=$(python3 -c 'import time; print(int(time.time()*1000))')
    echo $militime
}

total_tiff=0
check_directory () {
    # 1st argument the directoy that will be checked
    # 2nd argument is the output root directory
    start_time=$(get_mili_sec)
    for file in "$1"/*
      do
        if [ -d "$file" ]; then
            check_directory "$file" "$2"
        elif [ -f "$file" ]; then
            if [ "${file##*.}"x = "tid"x ]; then
                # echo "processing $file"
                file_path=$(dirname "$file")
                file_no_dir=${file##*/}
                file_no_ext=${file_no_dir%.tid}
                out_path="$2/$file_path"
                file_out_name="$file_no_ext"
                mkdir -p "$out_path"
                convert_single_file "$file" "$out_path/$file_out_name.md"
            fi
        fi
      done
}


check_directory $1 $2
