#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop with parallel execution
# Usage: ./ralph.sh [max_iterations] [max_parallel]

set -e

MAX_ITERATIONS=${1:-20}
MAX_PARALLEL=${2:-3}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_BRANCH_FILE="$SCRIPT_DIR/.last-branch"
LOCK_FILE="$SCRIPT_DIR/.ralph.lock"
OUTPUT_DIR="$SCRIPT_DIR/.ralph-output"

# Cleanup function
cleanup() {
  rm -f "$LOCK_FILE"
  rm -rf "$OUTPUT_DIR"
  # Kill any background processes
  jobs -p | xargs -r kill 2>/dev/null || true
}
trap cleanup EXIT

# Create output directory for parallel runs
mkdir -p "$OUTPUT_DIR"

# Function to parse reset time and wait until then
wait_for_rate_limit_reset() {
  local output="$1"

  # Extract reset time like "1:30am" or "2:45pm" from output
  local reset_time=$(echo "$output" | grep -oP 'resets\s+\K\d{1,2}:\d{2}(am|pm)' | head -1)

  if [ -z "$reset_time" ]; then
    echo "Could not parse reset time, waiting 30 minutes as fallback..."
    sleep 1800
    return
  fi

  echo ""
  echo "╔═══════════════════════════════════════════════════════╗"
  echo "║  Rate limit hit! Reset time: $reset_time"
  echo "╚═══════════════════════════════════════════════════════╝"

  # Parse hour and minute
  local hour=$(echo "$reset_time" | grep -oP '^\d{1,2}')
  local minute=$(echo "$reset_time" | grep -oP ':\K\d{2}')
  local ampm=$(echo "$reset_time" | grep -oP '(am|pm)$')

  # Convert to 24-hour format
  if [ "$ampm" = "pm" ] && [ "$hour" -ne 12 ]; then
    hour=$((hour + 12))
  elif [ "$ampm" = "am" ] && [ "$hour" -eq 12 ]; then
    hour=0
  fi

  # Get current time components
  local current_hour=$(date +%H)
  local current_minute=$(date +%M)
  local current_seconds=$(date +%S)

  # Calculate seconds until reset
  local target_seconds=$((hour * 3600 + minute * 60))
  local current_total_seconds=$((10#$current_hour * 3600 + 10#$current_minute * 60 + 10#$current_seconds))

  local wait_seconds=$((target_seconds - current_total_seconds))

  # If negative, reset is tomorrow
  if [ $wait_seconds -lt 0 ]; then
    wait_seconds=$((wait_seconds + 86400))
  fi

  # Add 1 minute buffer
  wait_seconds=$((wait_seconds + 60))

  local wait_minutes=$((wait_seconds / 60))
  local wait_hours=$((wait_minutes / 60))
  local remaining_minutes=$((wait_minutes % 60))

  echo "Current time: $(date '+%H:%M:%S')"
  echo "Waiting ${wait_hours}h ${remaining_minutes}m until reset + 1 minute buffer..."
  echo "Will resume at: $(date -d "+${wait_seconds} seconds" '+%H:%M:%S')"
  echo ""

  sleep $wait_seconds
  echo "Rate limit should be reset. Resuming..."
}

# Function to get ready stories (dependencies satisfied, not yet passed)
get_ready_stories() {
  jq -r '
    .userStories as $all |
    .userStories[] |
    select(.passes == false) |
    select(
      .dependsOn == [] or
      (.dependsOn | all(. as $dep | $all | map(select(.id == $dep and .passes == true)) | length > 0))
    ) |
    .id
  ' "$PRD_FILE" 2>/dev/null
}

# Function to check if all stories are complete
all_stories_complete() {
  local incomplete=$(jq '[.userStories[] | select(.passes == false)] | length' "$PRD_FILE" 2>/dev/null)
  # Handle empty or non-numeric result
  if [ -z "$incomplete" ] || ! [[ "$incomplete" =~ ^[0-9]+$ ]]; then
    return 1  # Not complete if we can't read the file
  fi
  [ "$incomplete" -eq 0 ]
}

# Function to run a single story
run_story() {
  local story_id="$1"
  local output_file="$OUTPUT_DIR/${story_id}.output"

  echo "  Starting: $story_id"

  # Create a prompt that targets this specific story
  local PROMPT=$(cat "$SCRIPT_DIR/prompt.md")
  PROMPT="$PROMPT

---
**IMPORTANT: You are assigned to implement story $story_id specifically.**
Pick story $story_id from the PRD and implement it. Do not pick any other story."

  # Run claude and capture output
  claude -p "$PROMPT" --dangerously-skip-permissions > "$output_file" 2>&1 || true

  echo "  Finished: $story_id"
}

# Archive previous run if branch changed
if [ -f "$PRD_FILE" ] && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")

  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    DATE=$(date +%Y-%m-%d)
    FOLDER_NAME=$(echo "$LAST_BRANCH" | sed 's|^ralph/||')
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"

    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    echo "   Archived to: $ARCHIVE_FOLDER"

    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"
  fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

echo "Starting Ralph - Max iterations: $MAX_ITERATIONS, Max parallel: $MAX_PARALLEL"
echo ""

# Verify PRD file exists and is valid JSON
if [ ! -f "$PRD_FILE" ]; then
  echo "Error: PRD file not found at $PRD_FILE"
  echo "Create a prd.json file first using the /ralph or /prd skill."
  exit 1
fi

if ! jq empty "$PRD_FILE" 2>/dev/null; then
  echo "Error: PRD file is not valid JSON: $PRD_FILE"
  exit 1
fi

iteration=0
while [ $iteration -lt $MAX_ITERATIONS ]; do
  iteration=$((iteration + 1))

  # Check if all stories are complete
  if all_stories_complete; then
    echo ""
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║  Ralph completed all tasks!                           ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo "Completed at iteration $iteration of $MAX_ITERATIONS"
    exit 0
  fi

  # Get ready stories
  READY_STORIES=$(get_ready_stories)

  if [ -z "$READY_STORIES" ]; then
    echo "No ready stories found (possible circular dependency or all complete)"
    sleep 5
    continue
  fi

  # Count ready stories
  READY_COUNT=$(echo "$READY_STORIES" | wc -l)

  # Limit to MAX_PARALLEL
  if [ "$READY_COUNT" -gt "$MAX_PARALLEL" ]; then
    READY_STORIES=$(echo "$READY_STORIES" | head -n "$MAX_PARALLEL")
    READY_COUNT=$MAX_PARALLEL
  fi

  echo "═══════════════════════════════════════════════════════"
  echo "  Ralph Iteration $iteration of $MAX_ITERATIONS"
  echo "  Ready stories: $READY_COUNT (running in parallel)"
  echo "═══════════════════════════════════════════════════════"
  echo ""

  # Clear previous output files
  rm -f "$OUTPUT_DIR"/*.output

  # Launch stories in parallel
  PIDS=()
  STORY_IDS=()

  for story_id in $READY_STORIES; do
    run_story "$story_id" &
    PIDS+=($!)
    STORY_IDS+=("$story_id")
  done

  echo ""
  echo "Waiting for ${#PIDS[@]} parallel tasks to complete..."
  echo ""

  # Wait for all background jobs
  RATE_LIMITED=false
  for i in "${!PIDS[@]}"; do
    pid=${PIDS[$i]}
    story_id=${STORY_IDS[$i]}

    wait $pid || true

    # Check output for rate limit
    output_file="$OUTPUT_DIR/${story_id}.output"
    if [ -f "$output_file" ]; then
      OUTPUT=$(cat "$output_file")

      # Display output (truncated)
      echo "─── Output for $story_id ───"
      echo "$OUTPUT" | tail -50
      echo "────────────────────────────"
      echo ""

      # Check for rate limit
      if echo "$OUTPUT" | grep -qi "out of.*usage.*resets"; then
        RATE_LIMITED=true
        RATE_LIMIT_OUTPUT="$OUTPUT"
      fi

      # Check for completion signal
      if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo ""
        echo "╔═══════════════════════════════════════════════════════╗"
        echo "║  Ralph completed all tasks!                           ║"
        echo "╚═══════════════════════════════════════════════════════╝"
        echo "Completed at iteration $iteration of $MAX_ITERATIONS"
        exit 0
      fi
    fi
  done

  # Handle rate limit if detected
  if [ "$RATE_LIMITED" = true ]; then
    wait_for_rate_limit_reset "$RATE_LIMIT_OUTPUT"
    # Don't count this as an iteration since work may not have completed
    iteration=$((iteration - 1))
    continue
  fi

  echo "Iteration $iteration complete. Checking for more ready stories..."
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
