#!/usr/bin/env bash
# Generic runner: runs code/tasks/<task_id>/main.py; stdout goes to a file sent only to Telegram.
set -u
ROOT="$GITHUB_WORKSPACE"
inp() { python3 -c 'import json,os,sys;print((json.load(open(os.environ["GITHUB_EVENT_PATH"])).get("inputs") or {}).get(sys.argv[1],"") or "")' "$1"; }
TASK_ID="$(inp task_id)"; export TASK_ID
TASK_INPUT="$(inp task_input)"; export TASK_INPUT
case "$TASK_ID" in ""|*[!A-Za-z0-9_-]*) echo "bad task id"; exit 1;; esac
dir="$ROOT/code/tasks/$TASK_ID"
[ -d "$dir" ] || { echo "task not found"; exit 1; }
cd "$dir" && mkdir -p output
(
  set -o pipefail
  if [ -f setup.sh ]; then bash setup.sh || exit $?; fi
  if [ -f requirements.txt ]; then pip install -q -r requirements.txt || exit $?; fi
  python main.py
) > output/log.txt 2>&1
rc=$?
s=0
if [ "$rc" -eq 0 ]; then bash "$ROOT/.github/scripts/tg_send.sh" output > "$RUNNER_TEMP/send.txt" 2>&1; s=$?; fi
{ echo "exit_code=$rc telegram_send=$s"; tail -n 3 "$RUNNER_TEMP/send.txt" 2>/dev/null | sed -E 's#bot[0-9]+:[A-Za-z0-9_-]+#bot***#g'; echo "---"; tail -n 200 output/log.txt; } > "$RUNNER_TEMP/runlog.txt"
python3 "$ROOT/.github/scripts/save_log.py" "$RUNNER_TEMP/runlog.txt" "tasks/$TASK_ID/_last_run.log" >/dev/null 2>&1 || true
rm -rf output "$RUNNER_TEMP/runlog.txt" "$RUNNER_TEMP/send.txt"
echo "exit=$rc send=$s"
[ "$rc" -eq 0 ] && [ "$s" -eq 0 ]
