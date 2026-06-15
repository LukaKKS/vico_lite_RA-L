#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MODEL=${MODEL:-"gpt-4o-mini"}
RUN_ID=${RUN_ID:-"vico_agent_test"}
EPISODES=${EPISODES:-"0"}
PORT=${PORT:-1072}
PYTHON=${PYTHON:-python}

ENV_FILE="${ENV_FILE:-$ROOT/.env}"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

echo "[run_vico_agent] model=$MODEL, episodes=$EPISODES, run_id=$RUN_ID, port=$PORT"

PIDS=$(lsof -ti tcp:"$PORT" 2>/dev/null || true)
if [ -n "$PIDS" ]; then
  echo "Killing any existing TDW processes on port $PORT..."
  kill -9 $PIDS || true
fi

export VICO_REASONER_MODEL=$MODEL

"$PYTHON" tdw-gym/challenge.py \
  --agents vico_agent vico_agent \
  --data_path test_env.json \
  --data_prefix dataset/dataset_test/ \
  --experiment_name vico_lite \
  --run_id "$RUN_ID" \
  --communication \
  --eval_episodes $EPISODES \
  --port "$PORT" \
  --screen_size 512 \
  --no_save_img \
  "$@"

PIDS=$(lsof -ti tcp:"$PORT" 2>/dev/null || true)
if [ -n "$PIDS" ]; then
  kill -9 $PIDS || true
fi
