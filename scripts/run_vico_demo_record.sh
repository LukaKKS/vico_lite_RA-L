#!/bin/bash
# ViCo-Lite demo run: large viewport + frame dumps for video editing.
set -e

ROOT="/Users/giseong/Desktop/multi_agent/vico/CoELA/tdw_mat"
cd "$ROOT"

MODEL=${MODEL:-"gpt-4o-mini"}
RUN_ID=${RUN_ID:-"demo_record"}
EPISODES=${EPISODES:-"0"}
PORT=${PORT:-1075}
SCREEN_SIZE=${SCREEN_SIZE:-1024}
MAX_FRAMES=${MAX_FRAMES:-600}

ENV_FILE="/Users/giseong/Desktop/multi_agent/vico/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

echo "[run_vico_demo_record] run_id=$RUN_ID episodes=$EPISODES port=$PORT screen=$SCREEN_SIZE max_frames=$MAX_FRAMES"

PIDS=$(lsof -ti tcp:"$PORT" 2>/dev/null || true)
if [ -n "$PIDS" ]; then
  echo "Killing processes on port $PORT: $PIDS"
  kill -9 $PIDS || true
  sleep 1
fi

source /Users/giseong/miniforge3/bin/activate vico
export VICO_REASONER_MODEL=$MODEL

PYTHON="/Users/giseong/miniforge3/envs/vico/bin/python"
OUT_BASE="results/vico_demo/${RUN_ID}"

echo "Output: ${OUT_BASE}/<episode>/Images/ and top_down_image/"

"$PYTHON" tdw-gym/challenge.py \
  --agents vico_agent vico_agent \
  --output_dir results \
  --data_path test_env.json \
  --data_prefix dataset/dataset_test/ \
  --experiment_name vico_demo \
  --run_id "$RUN_ID" \
  --communication \
  --eval_episodes $EPISODES \
  --port "$PORT" \
  --screen_size "$SCREEN_SIZE" \
  --max_frames "$MAX_FRAMES" \
  "$@"

PIDS=$(lsof -ti tcp:"$PORT" 2>/dev/null || true)
if [ -n "$PIDS" ]; then
  kill -9 $PIDS || true
fi

echo "Done. Build videos with: bash scripts/make_demo_video.sh $RUN_ID 0"
