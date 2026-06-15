# ViCo-Lite on TDW Multi-Agent Transport

Lightweight multi-agent transport agents with **distributed ego-centric perception**, **team shared memory**, and **heuristic control** (optional LLM reasoner).

Built on [TDW Multi-Agent Transport](https://github.com/embodied-agent-interface/CoELA) (CoELA `tdw_mat`).

## Layout

```
vico_lite/              ViCo-Lite policy, perception (CLIP), memory bridge
tdw-gym/vico_agent.py   Gym agent wrapper
tdw-gym/challenge.py    Evaluation entry (supports --stop_on_first_success)
scripts/                run_vico_agent.sh, run_vico_screen_record.sh
dataset/dataset_test/   24-episode test split
```

## Setup

```bash
conda create -n vico_lite python=3.9
conda activate vico_lite
pip install -e .
pip install git+https://github.com/openai/CLIP.git
```

Optional: copy `.env.example` to `.env` and set `OPENAI_API_KEY` if using LLM reasoner/guidance.

## Run

Two ViCo agents on test episode 0:

```bash
bash scripts/run_vico_agent.sh
```

Screen recording (no image dumps, stop after first `put_in` on bed):

```bash
bash scripts/run_vico_screen_record.sh
```

Logs: `results/vico_lite/<run_id>/<episode>/output.log`

## Key flags (`challenge.py`)

| Flag | Description |
|------|-------------|
| `--agents vico_agent vico_agent` | Two ViCo-Lite agents |
| `--communication` | Inter-agent messaging |
| `--no_save_img` | Skip RGB/map frame dumps |
| `--stop_on_first_success` | End episode after first successful `put_in` |
| `--screen_size 1024` | Larger Unity viewport for recording |

## Citation

If you use this code, please cite the ViCo-Lite / RA-L paper (add citation when available).
