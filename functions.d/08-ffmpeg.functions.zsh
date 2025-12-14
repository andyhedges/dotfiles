
# ffhevc50: Transcode video to HEVC using VideoToolbox at 50 Mbps
# VideoToolbox usings hardware acceleration on mac but isn't
# as high wality as h265 software encoding in ffmpeg
ff50() {
  if [ $# -eq 0 ]; then
    echo "Usage: ff50 <inputfile>"
    return 1
  fi

  local infile="$1"
  local outfile="${infile%.*}_processed.${infile##*.}"

  ffmpeg -i "$infile" \
    -c:v hevc_videotoolbox -b:v 50M -maxrate 50M -bufsize 100M -tag:v hvc1 \
    -pix_fmt yuv420p -c:a copy -movflags +faststart \
    "$outfile"
}

transcode_codec() {
  emulate -L zsh
  setopt pipefail

  local input="" target="" output="" encoder="" enc_args=""

  show_help() {
    cat <<'EOF'
Usage:
  transcode_codec -i <input> -t <codec> [options]

Required:
  -i <file>        Input media file
  -t <codec>       Target video codec (h264 | hevc | av1 | vp9)

Optional:
  -o <file>        Output file (default: <input>.<codec>.mkv)
  -e <encoder>     ffmpeg encoder (default chosen from codec)
  -a "<args>"      Extra encoder args (quoted)
  -h               Help

Examples:
  transcode_codec -i input.mp4 -t hevc
  transcode_codec -i input.mp4 -t hevc -e hevc_videotoolbox -a "-b:v 20M"
  transcode_codec -i input.mp4 -t hevc -e libx265 -a "-crf 22 -preset medium"
EOF
  }

  while getopts ":i:t:o:e:a:h" opt; do
    case "$opt" in
      i) input="$OPTARG" ;;
      t) target="$OPTARG" ;;
      o) output="$OPTARG" ;;
      e) encoder="$OPTARG" ;;
      a) enc_args="$OPTARG" ;;
      h) show_help; return 0 ;;
      :) print -u2 "Option -$OPTARG requires an argument"; return 2 ;;
      \?) print -u2 "Unknown option: -$OPTARG"; show_help; return 2 ;;
    esac
  done

  [[ -n "$input" && -n "$target" ]] || { show_help; return 2; }
  [[ -f "$input" ]] || { print -u2 "Input not found: $input"; return 2; }
  command -v ffmpeg  >/dev/null || { print -u2 "ffmpeg not found"; return 2; }
  command -v ffprobe >/dev/null || { print -u2 "ffprobe not found"; return 2; }

  local cur_codec
  cur_codec="$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name -of default=nw=1:nk=1 "$input")"
  [[ -n "$cur_codec" ]] || { print -u2 "Could not detect video codec"; return 1; }

  local duration
  duration="$(ffprobe -v error -show_entries format=duration \
    -of default=nw=1:nk=1 "$input")"

  [[ -n "$output" ]] || output="${input:h}/${input:t:r}.${target}.mkv"

  if [[ "$cur_codec" == "$target" ]]; then
    if [[ "$output" != "$input" ]]; then
      cp -p "$input" "$output"
      print "Already $target, copied → $output"
      print -r -- "$output"
      return 0
    fi
    print "Already $target, no work"
    print -r -- "$input"
    return 0
  fi

  if [[ -z "$encoder" ]]; then
    case "$target" in
      h264) encoder="libx264" ;;
      hevc) encoder="libx265" ;;
      av1)  encoder="libsvtav1" ;;
      vp9)  encoder="libvpx-vp9" ;;
      *) print -u2 "Unknown target codec: $target"; return 2 ;;
    esac
  fi

  local -a enc_args_arr
  [[ -n "$enc_args" ]] && enc_args_arr=(${=enc_args}) || enc_args_arr=()

  local start=$(date +%s)
  local width=30
  draw_bar() {
    local pct=$1
    (( pct < 0 )) && pct=0
    (( pct > 100 )) && pct=100
    local filled=$(( pct * width / 100 ))
    printf "[%s%s] %3d%%" \
      "${(l:$filled::█:)}" \
      "${(l:$((width-filled)):: :)}" \
      "$pct"
  }

  # Progress parser runs via FD 3, so ffmpeg is not in a pipeline.
  # Stderr remains real stderr, so you will SEE the actual failure reason.
  {
    while IFS='=' read -r key val; do
      [[ "$key" == "out_time_ms" ]] || continue
      local sec=$(( val / 1000000 ))
      local elapsed=$(( $(date +%s) - start ))

      if [[ -n "$duration" && "$duration" != "N/A" ]]; then
        local pct
        pct="$(printf "%.0f" "$(echo "$sec*100/$duration" | bc -l 2>/dev/null)")"
        [[ -n "$pct" ]] && printf "\r%s  elapsed %3ds" "$(draw_bar "$pct")" "$elapsed"
      else
        printf "\rtime %5ds  elapsed %3ds" "$sec" "$elapsed"
      fi
    done
  } 3< <(
    ffmpeg -hide_banner -y \
      -i "$input" \
      -map 0 -map_metadata 0 \
      -c copy \
      -c:v:0 "$encoder" "${enc_args_arr[@]}" \
      -progress pipe:3 -nostats \
      "$output" \
      3>&1 1>/dev/null
  )

  local rc=$?
  echo

  if (( rc != 0 )); then
    # Remove the empty or partial file to avoid confusion
    rm -f -- "$output"
    print -u2 "ffmpeg failed (exit $rc). Output removed: $output"
    return $rc
  fi

  print -r -- "$output"
}
