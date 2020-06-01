#!/bin/bash

convert_single_file () {
    # The 1st argument is the txt file (with the full path)
    # The 2nd argument is the tid file
    file_no_dir=${2##*/}
    file_path_no_root=${2#*/}
    file_path=$(dirname "$file_path_no_root" | sed 's#/#:#g') # First replace / by : (we will replace back to )
    file_no_ext=${file_no_dir%.tid}
    file_leading_dir=$(echo "$file_path_no_root" | awk -F'/' '{print $1}')

    # The format of the time in zim and tiddly is different
    creation_date_in_zim=$(sed -n '3p' "$1" | cut -d ' ' -f 2 | sed 's/[^[:digit:]]//g')
    # echo "$creation_date_in_zim time"
    creation_date_in_tid=${creation_date_in_zim:0:17}

    title="${file_path_no_root%.tid}"
    caption=$(sed -n '5p' "$1" | sed 's/====== //g' | sed 's/ ======//g') #Get the caption


    # The header part of the tid file
    echo "caption: $caption" > "$2"
    echo "created: $creation_date_in_tid" >> "$2"
    echo "modified: $creation_date_in_tid" >> "$2"
    echo "tags: " >> "$2"
    echo "title: $title" >> "$2"
    echo "type: text/vnd.tiddlywiki" >> "$2"
    echo "" >> "$2"
    echo "" >> "$2"
    echo "! $caption" >> "$2"

    # The body
    # italics no need
    # Mark (underline) no need
    # Strike no need
    sed -e '6,$G' `# Add empty line between each line` \
    -e '1,6d' `# Delete header from zim ` \
    -e 's/=\{6\} \(.*\) =\{6\}/! \1/g' \
    -e 's/=\{5\} \(.*\) =\{5\}/!! \1/g' \
    -e 's/=\{4\} \(.*\) =\{4\}/!!! \1/g' \
    -e 's/=\{3\} \(.*\) =\{3\}/!!!! \1/g' \
    -e 's/=\{2\} \(.*\) =\{2\}/!!!!! \1/g' `# Headings` \
    -e 's/-\{20\}/---/g' `# Horizontal Rules` \
    -e "s/\'\'\([^\']*\)\'\'/\`\1\`/g" `# verbatim` \
    -e 's/{{{code: lang="\([^"]*\)" .*/\`\`\`\1/g' `# code block head` \
    -e "s/}}}/\`\`\`/g" `# code block end` \
    -e "s/\*\*\([^\*]*\)\*\*/\'\'\1\'\'/g" `# emphasis` \
    -e 's/^[[:space:]]\*/\*\*/g' \
    -e 's/^[[:space:]]\{2\}\*/\*\*\*/g' \
    -e 's/^[[:space:]]\{3\}\*/\*\*\*\*/g' \
    -e 's/^[[:space:]]\{4\}\*/\*\*\*\*\*/g' \
    -e 's/^[[:space:]]\{5\}\*/\*\*\*\*\*\*/g' `# no-order list, the leading one is the same,` \
    -e 's/^[[:alnum:]]\./# /g' \
    -e 's/^[[:space:]][[:alnum:]]\./## /g' \
    -e 's/^[[:space:]]\{2\}[[:alnum:]]\./### /g' \
    -e 's/^[[:space:]]\{3\}[[:alnum:]]\./#### /g' \
    -e 's/^[[:space:]]\{4\}[[:alnum:]]\./##### /g' `# ordered list # Currently I can't handle mixed list` \
    -e "s#\[\[arXiv\?\([[:digit:]]*\.[[:digit:]]*\)\]\]#(arXiv:\1)#g" `#arXiv link for 1606.12345 type`\
    -e "s#\[\[arXiv\?\(.*/[[:digit:]]*\)\]\]#(arXiv:\1)#g" `#arXiv line for hep-ph/234353 type`\
    -e "s#\[\[wp\?\(.*\)|\(.*\)\]\]#(wikipedia:\1)#g" \
    -e "s#\[\[wp\?\(.*\)\]\]#(wikipedia:\1)#g" \
    -e "s/\[\[\([^:\+\.]\{1\}[^|\[]*\)\]\]/\[\[\1|${file_path}:\1\]\]/g" `## Link [[xxxxxx]]` \
    -e "s/\[\[\([^:\+\.]\{1\}[^|\[]*\)|\([^|\[]*\)\]\]/\[\[\2|${file_path}:\1\]\]/g" `## Link [[xxxxxxxx|xxxxxx]]` \
    -e 's/\[\[\.\/\([^\[]*\.pdf\)|\(.*\)\]\]/\[\[\2|\1\]\]/g' `# Attachments (for me, only pdf)` \
    -e "s/\[\[:\([^\[]*\)|\([^\[]*\)\]\]/\[\[\2|${file_leading_dir}:\1\]\]/g" `## Link [[:xxxxxxx|xxxxxx]]` \
    -e "s/\[\[:\([^\[]*\)\]\]/\[\[${file_leading_dir}:\1\]\]/g" `## Link [[:xxxxx]]` \
    -e "s/\[\[\+\([^\[]*\)|\([^\[]*\)\]\]/\[\[\2|${file_path}:${file_no_ext}:\1\]\]/g" `## Link [[+xxxxxxx|xxxxxx]]` \
    -e "s/\[\[\+\([^\[]*\)\]\]/\[\[\1|${file_path}:${file_no_ext}:\1\]\]/g" `## Link [[+xxxxx]]` \
    -e 's#:\([^[:space:]*]\)#/\1#g' `## Replace all : to / (I can bear with other : replaced by /)` \
    "$1" | \
    sed -e 's#^{{\./\(equation[[:digit:]]*\)\.png\?type=equation}}#\$\$\
\\begin{aligned}\
__\1\.tex__\
\\end{aligned}\
\$\$#g' `## Displayed math, need to replace tex later` \
    | \
    sed -e "s/{{\.\/\(equation[[:digit:]]*\)\.png\?type=equation}}/\$\$__\1\.tex__\$\$/g" `## inline math, need to replace tex later` \
    -e "s/{{\.\/\(pasted_image[[:digit:]]*\)\.tiff\?width=\([[:digit:]]*\)}}/\[img width=\2 \[__\1\.png__\]\]/g" `# Plots (remember to convert tiff to png)` \
    -e "s/{{\.\/\(pasted_image[[:digit:]]*\)\.tiff}}/\[img\[__\1\.png__\]\]/g" `# Plots without width information` \
     >> "$2"
    

}

replace_tex () {
    tex_no_dir=${2##*/}
    tex_name=${tex_no_dir%.tex}
    tex_content=$(cat "$2" | sed -e "s/\\\/__SLASH__/g" -e "s/\&/__AND__/g" | grep -v '^$' )
    tex_n_line=$(echo "$tex_content" | wc -l)
    if [ $tex_n_line -eq 1 ]; then
        sed "s#__${tex_name}\.tex__#${tex_content}#g" "$1" > "$1.tmp"
        sed "s/__SLASH__/\\\/g" "$1.tmp" > "$1"
        rm "$1.tmp"
    else
        tex_in_one_line=$(echo "$tex_content" | sed "s/^\(.*\)$/\1__LINE_END__/g" | sed '$s/__LINE_END__//g' | tr '\n' ' ')
        sed "s#__${tex_name}\.tex__#${tex_in_one_line}#g" "$1" > "$1.tmp"
        sed -e 's/__LINE_END__/\
/g' -e "s/__SLASH__/\\\/g" -e "s/__AND__/\&/g" "$1.tmp" > "$1"
        rm "$1.tmp"
    fi
    # sed -e "/__${texname}\.tex__/ r "
    # echo "haha"
}

replace_tiff () {
    tiff_no_dir=${2##*/}
    tiff_name=${tiff_no_dir%.tiff}
    sed "s#__${tiff_name}\.png__#${3}#g" "$1" > "$1.tmp" # In mac and linux, the in-place modification has different syntax, so I use one more step to avoid that
    cat "$1.tmp" > "$1"
    rm "$1.tmp"
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
    for file in $1/*
      do
        if [ -d "$file" ]; then
            check_directory $file $2
        elif [ -f "$file" ]; then
            if [ "${file##*.}"x = "txt"x ]; then
                # echo "processing $file"
                file_path=$(dirname $file)
                file_no_dir=${file##*/}
                file_no_ext=${file_no_dir%.txt}
                out_path=$(echo "$2/$file_path" | sed 's/_/ /g')
                file_out_name=$(echo "$file_no_ext" | sed 's/_/ /g' )
                mkdir -p "$out_path"
                convert_single_file $file "$out_path/$file_out_name.tid"
                if [ -d "${file%.txt}" ]; then
                    # if there is a directoy with the same name (without extension), then we need to check whether we should replace tex formula, and rename tiff (screenshot) files
                    for auxfile in ${file%.txt}/*
                      do
                        if [ "${auxfile##*.}"x = "tex"x ]; then
                            # handle tex file
                            # echo "$out_path/$file_no_ext.tid  with $auxfile"
                            replace_tex "$out_path/$file_out_name.tid" $auxfile
                        elif [ "${auxfile##*.}"x = "tiff"x ]; then
                            total_tiff=$[$total_tiff+1]
                            mkdir -p $2/Figures
                            aux_path=$(dirname $auxfile)
                            aux_file=${auxfile##*/}
                            aux_filename=${aux_file%.tiff}
                            suffix=$(echo "${aux_filename}" | sed "s/[^[:digit:]]//g" )
                            tiff_id=${suffix:-000}
                            time_stamp=$(date +%Y%m%d%H%M%S)
                            current_time=$(get_mili_sec)
                            diff_time=$[$current_time - $start_time]
                            mili_sec=$(expr $diff_time % 1000 | awk '{printf("%03d",$0)}')
                            png_name=SS_${time_stamp}${mili_sec}_${tiff_id}.png
                            convert ${auxfile} $2/Figures/$png_name
                            png_meta_data=${png_name}.meta
                            echo "created: ${time_stamp}${mili_sec}" > $2/Figures/$png_meta_data
                            echo "modified: ${time_stamp}${mili_sec}" >> $2/Figures/$png_meta_data
                            echo "title: $png_name" >> $2/Figures/$png_meta_data
                            echo "type: image/png" >> $2/Figures/$png_meta_data
                            replace_tiff "$out_path/$file_out_name.tid" $auxfile $png_name
                        fi
                      done
                fi
                # echo "From $file to $out_path/$file_no_ext.tid"
            fi
        fi
      done
}


check_directory $1 $2
