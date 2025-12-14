
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

# Usage:
#   transcode_codec input.mp4 hevc
#   transcode_codec input.mp4 h264 output.mkv
#   transcode_codec input.mp4 av1 output.mkv libsvtav1 "-crf 28 -preset 6"

transcode_codec() {
  emulate -L zsh
  setopt pipefail

  local in="$1"
  local target="$2"
  local out="$3"
  local encoder="$4"
  local enc_args_str="$5"

  if [[ -z "$in" || -z "$target" ]]; then
    print -u2 "Usage: transcode_codec <input> <target_codec> [output] [encoder] [\"encoder args\"]"
    return 2
  fi
  [[ -f "$in" ]] || { print -u2 "Input not found: $in"; return 2 }

  command -v ffmpeg >/dev/null || { print -u2 "ffmpeg not found"; return 2 }
  command -v ffprobe >/dev/null || { print -u2 "ffprobe not found"; return 2 }

  # Current codec
  local cur_codec
  cur_codec="$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name \
    -of default=nw=1:nk=1 "$in")"

  [[ -n "$cur_codec" ]] || { print -u2 "Could not detect codec"; return 1 }

  # Duration in seconds
  local duration
  duration="$(ffprobe -v error -show_entries format=duration \
    -of default=nw=1:nk=1 "$in")"

  # Output path
  if [[ -z "$out" ]]; then
    local stem="${in:t:r}"
    out="${in:h}/${stem}.${target}.mkv"
  fi

  # No-op
  if [[ "$cur_codec" == "$target" ]]; then
    if [[ "$out" != "$in" ]]; then
      cp -p "$in" "$out"
      print "Already $target, copied → $out"
      print -r -- "$out"
      return 0
    fi
    print "Already $target, no work"
    print -r -- "$in"
    return 0
  fi

  # Default encoder
  if [[ -z "$encoder" ]]; then
    case "$target" in
      hevc) encoder="libx265" ;;
      h264) encoder="libx264" ;;
      av1)  encoder="libsvtav1" ;;
      vp9)  encoder="libvpx-vp9" ;;
      *)
        print -u2 "No default encoder for '$target'"
        return 2
      ;;
    esac
  fi

  # Encoder args
  local -a enc_args
  [[ -n "$enc_args_str" ]] && enc_args=(${=enc_args_str}) || enc_args=()

  # Start time
  local start
  start="$(date +%s)"

  # Progress bar
  local width=30
  draw_bar() {
    local pct="$1"
    (( pct < 0 )) && pct=0
    (( pct > 100 )) && pct=100
    local filled=$(( pct * width / 100 ))
    printf "[%s%s] %3d%%" \
      "${(l:$filled::█:)}" \
      "${(l:$((width-filled)):: :)}" \
      "$pct"
  }

  ffmpeg -hide_banner -y \
    -i "$in" \
    -map 0 -map_metadata 0 \
    -c copy \
    -c:v:0 "$encoder" "${enc_args[@]}" \
    -progress pipe:1 -nostats \
    "$out" | while IFS='=' read -r key val; do

      [[ "$key" == "out_time_ms" ]] || continue

      # microseconds → seconds
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

  print -r -- "$out"
}
