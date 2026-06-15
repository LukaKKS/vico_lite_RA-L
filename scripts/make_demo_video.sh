#!/bin/bash
# Build MP4s from saved ViCo demo frames (requires ffmpeg).
set -euo pipefail

ROOT="/Users/giseong/Desktop/multi_agent/vico/CoELA/tdw_mat"
cd "$ROOT"

RUN_ID=${1:-demo_record}
EPISODE=${2:-0}
FPS=${3:-8}

BASE="results/vico_demo/${RUN_ID}/${EPISODE}"
OUT_DIR="results/vico_demo/${RUN_ID}/videos"
mkdir -p "$OUT_DIR"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg not found. Install with: brew install ffmpeg"
  exit 1
fi

make_rgb_video() {
  local agent_id=$1
  local label=$2
  local indir="${BASE}/Images/${agent_id}"
  local outfile="${OUT_DIR}/${label}_ego.mp4"

  if [ ! -d "$indir" ]; then
    echo "Skip ${label}: missing ${indir}"
    return 1
  fi

  # Only step_frame RGB (exclude _seg, _depth, _map)
  local count
  count=$(find "$indir" -maxdepth 1 -type f -name '*.png' ! -name '*_*' 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" = "0" ]; then
    # fallback: exclude known suffixes
    count=$(find "$indir" -maxdepth 1 -type f -name '*.png' ! -name '*_seg.png' ! -name '*_depth.png' ! -name '*_map.png' 2>/dev/null | wc -l | tr -d ' ')
  fi
  if [ "$count" = "0" ]; then
    echo "Skip ${label}: no RGB png in ${indir}"
    return 1
  fi

  local list="${OUT_DIR}/.frame_list_${label}.txt"
  find "$indir" -maxdepth 1 -type f -regex '.*/[0-9]+_[0-9]+\.png$' | sort > "$list"
  count=$(wc -l < "$list" | tr -d ' ')
  if [ "$count" = "0" ]; then
    echo "Skip ${label}: no RGB frames (NNNN_MMMM.png)"
    return 1
  fi
  echo "Building ${outfile} (${count} frames @ ${FPS} fps)..."
  ffmpeg -y -hide_banner -loglevel warning \
    -f concat -safe 0 -r "$FPS" -i "$list" \
    -vf "scale=1280:-2:flags=lanczos,format=yuv420p" \
    -c:v libx264 -pix_fmt yuv420p \
    "$outfile"
  rm -f "$list"
  echo "  -> ${outfile}"
}

make_topdown_video() {
  local indir="${BASE}/top_down_image"
  local outfile="${OUT_DIR}/top_down.mp4"
  if [ ! -d "$indir" ]; then
    echo "Skip top_down: missing ${indir}"
    return 1
  fi
  local count
  count=$(find "$indir" -maxdepth 1 -type f \( -name 'img_*.jpg' -o -name 'img_*.png' -o -name '*.jpg' -o -name '*.png' \) 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" = "0" ]; then
    echo "Skip top_down: no images"
    return 1
  fi
  echo "Building ${outfile} (${count} frames)..."
  local list="${OUT_DIR}/.frame_list_topdown.txt"
  find "$indir" -maxdepth 1 -type f \( -name 'img_*.jpg' -o -name 'img_*.png' \) | sort > "$list"
  ffmpeg -y -hide_banner -loglevel warning \
    -f concat -safe 0 -r "$FPS" -i "$list" \
    -vf "scale=1280:-2:flags=lanczos,format=yuv420p" \
    -c:v libx264 -pix_fmt yuv420p \
    "$outfile"
  rm -f "$list"
  echo "  -> ${outfile}"
}

make_side_by_side() {
  local a="${OUT_DIR}/agent0_ego.mp4"
  local b="${OUT_DIR}/agent1_ego.mp4"
  local out="${OUT_DIR}/dual_ego_side_by_side.mp4"
  if [ ! -f "$a" ] || [ ! -f "$b" ]; then
    echo "Skip side-by-side: need agent0 and agent1 ego mp4"
    return 1
  fi
  echo "Building ${out}..."
  ffmpeg -y -hide_banner -loglevel warning \
    -i "$a" -i "$b" \
    -filter_complex "[0:v][1:v]hstack=inputs=2[v]" \
    -map "[v]" -c:v libx264 -pix_fmt yuv420p \
    "$out"
  echo "  -> ${out}"
}

make_rgb_video 0 agent0 || true
make_rgb_video 1 agent1 || true
make_topdown_video || true
make_side_by_side || true

echo ""
echo "Videos in: ${OUT_DIR}/"
ls -la "${OUT_DIR}/" 2>/dev/null || true
