
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

  local input=""
  local target=""
  local output=""
  local encoder=""
  local enc_args=""

  # ---------- help ----------
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
  -a "<args>"      Extra encoder arguments (quoted)
  -h               Show this help

Examples:
  transcode_codec -i input.mp4 -t hevc
  transcode_codec -i input.mp4 -t hevc -e hevc_videotoolbox -a "-b:v 20M"
  transcode_codec -i input.mp4 -t hevc -o output.mp4 -e libx265 -a "-crf 22 -preset medium"

Notes:
  - Only the primary video stream is re-encoded
  - All other streams are copied unchanged
  - If the input is already in the target codec, no transcode occurs
  - MKV is used by default for maximum compatibility
EOF
  }

  # ---------- parse args ----------
  while getopts ":i:t:o:e:a:h" opt; do
    case "$opt" in
      i) input="$OPTARG" ;;
      t) target="$OPTARG" ;;
      o) output="$OPTARG" ;;
      e) encoder="$OPTARG" ;;
      a) enc_args="$OPTARG" ;;
      h)
        show_help
        return 0
        ;;
      :)
        print -u2 "Option -$OPTARG requires an argument"
        return 2
        ;;
      \?)
        print -u2 "Unknown option: -$OPTARG"
        show_help
        return 2
        ;;
    esac
  done

  [[ -n "$input" && -n "$target" ]] || {
    show_help
    return 2
  }

  [[ -f "$input" ]] || {
    print -u2 "Input not found: $input"
    return 2
  }

  command -v ffmpeg >/dev/null || { print -u2 "ffmpeg not found"; return 2 }
  command -v ffprobe >/dev/null || { print -u2 "ffprobe not found"; return 2 }

  # ---------- detect codec ----------
  local cur_codec
  cur_codec="$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name \
    -of default=nw=1:nk=1 "$input")"

  [[ -n "$cur_codec" ]] || {
    print -u2 "Could not detect video codec"
    return 1
  }

  # ---------- duration ----------
  local duration
  duration="$(ffprobe -v error -show_entries format=duration \
    -of default=nw=1:nk=1 "$input")"

  # ---------- output ----------
  if [[ -z "$output" ]]; then
    output="${input:h}/${input:t:r}.${target}.mkv"
  fi

  # ---------- no-op ----------
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

  # ---------- default encoders ----------
  if [[ -z "$encoder" ]]; then
    case "$target" in
      h264) encoder="libx264" ;;
      hevc) encoder="libx265" ;;
      av1)  encoder="libsvtav1" ;;
      vp9)  encoder="libvpx-vp9" ;;
      *)
        print -u2 "Unknown target codec: $target"
        return 2
      ;;
    esac
  fi

  local -a enc_args_arr
  [[ -n "$enc_args" ]] && enc_args_arr=(${=enc_args}) || enc_args_arr=()

  # ---------- progress ----------
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

  ffmpeg -hide_banner -y \
    -i "$input" \
    -map 0 -map_metadata 0 \
    -c copy \
    -c:v:0 "$encoder" "${enc_args_arr[@]}" \
    -progress pipe:1 -nostats \
    "$output" | while IFS='=' read -r key val; do

      [[ "$key" == "out_time_ms" ]] || continue

      local sec=$(( val / 1000000 ))
      local elapsed=$(( $(date +%s) - start ))

      if [[ -n "$duration" && "$duration" != "N/A" ]]; then
        local pct
        pct="$(printf "%.0f" "$(echo "$sec*100/$duration" | bc -l)")"
        printf "\r%s  elapsed %3ds" "$(draw_bar "$pct")" "$elapsed"
      else
        printf "\rtime %5ds  elapsed %3ds" "$sec" "$elapsed"
      fi
    done

  local rc=$?
  echo
  (( rc == 0 )) || { print -u2 "ffmpeg failed ($rc)"; return $rc }

  print -r -- "$output"
}
