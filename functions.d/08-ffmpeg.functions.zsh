
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

