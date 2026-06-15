#!/bin/bash
# Screen recording helper: no image dumps, logs only, quit after first put_in on bed.
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RUN_ID=${RUN_ID:-"screen_record"}
EPISODES=${EPISODES:-"0"}
PORT=${PORT:-1075}
SCREEN_SIZE=${SCREEN_SIZE:-1024}
PYTHON=${PYTHON:-python}

ENV_FILE="${ENV_FILE:-$ROOT/.env}"
if [ -f "$ENV_FILE" ]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

echo "[run_vico_screen_record] run_id=$RUN_ID episode=$EPISODES port=$PORT screen=$SCREEN_SIZE"
echo "  - No JPG/PNG dumps (--no_save_img)"
echo "  - Stops after first put_in on bed (--stop_on_first_success)"
echo "  - Logs: results/vico_screen/${RUN_ID}/<episode>/output.log"
echo ""
if [ -z "${SKIP_ENTER:-}" ]; then
  echo "Start OBS/QuickTime on the Unity window, then press Enter to launch TDW..."
  read -r _
fi

PIDS=$(lsof -ti tcp:"$PORT" 2>/dev/null || true)
if [ -n "$PIDS" ]; then
  kill -9 $PIDS || true
  sleep 1
fi

"$PYTHON" tdw-gym/challenge.py \
  --agents vico_agent vico_agent \
  --output_dir results \
  --data_path test_env.json \
  --data_prefix dataset/dataset_test/ \
  --experiment_name vico_screen \
  --run_id "$RUN_ID" \
  --communication \
  --eval_episodes $EPISODES \
  --port "$PORT" \
  --screen_size "$SCREEN_SIZE" \
  --max_frames 3000 \
  --no_save_img \
  --stop_on_first_success \
  "$@"

PIDS=$(lsof -ti tcp:"$PORT" 2>/dev/null || true)
if [ -n "$PIDS" ]; then
  kill -9 $PIDS || true
fi

echo ""
echo "Done. Logs: results/vico_screen/${RUN_ID}/${EPISODES}/output.log"
