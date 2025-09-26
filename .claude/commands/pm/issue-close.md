---
allowed-tools: Bash, Read, Write, LS
---

# Issue Close

Mark an issue as complete and close it on GitHub.

## Usage
```
/pm:issue-close <task_id> [completion_notes]
```

## Instructions

### 1. Find Local Task File and Extract GitHub Issue Number

```bash
# Find task file and extract GitHub issue number
bash -c '
ARGUMENTS="'$ARGUMENTS'"
find .claude/epics -name "$ARGUMENTS.md" -not -path "*/.archived/*" 2>/dev/null > /tmp/task-files.txt
task_file=$(head -1 /tmp/task-files.txt 2>/dev/null)
if [ -z "$task_file" ]; then
  echo "❌ No task file found for $ARGUMENTS"
  exit 1
fi

# Extract GitHub issue number from task file
github_url=$(grep "^github_url:" "$task_file" 2>/dev/null)
issue_number=$(echo "$github_url" | sed "s|.*/||")
if [ -z "$issue_number" ]; then
  echo "❌ No GitHub issue found for $ARGUMENTS. Run /pm:epic-sync first."
  exit 1
fi

# Export for later use
echo "$task_file" > /tmp/current_task_file.txt
echo "$issue_number" > /tmp/current_issue_number.txt
'
```

### 2. Detect Current Status (Smart Completion Detection)

Check current task status and detect if issue-sync was used:
```bash
bash -c '
ARGUMENTS="'$ARGUMENTS'"
task_file=$(cat /tmp/current_task_file.txt)

# Get current task status
current_status=$(grep "^status:" "$task_file" 2>/dev/null | sed "s/status: *//")

# Check if progress file exists (indicates issue-sync was used)
epic_name=$(basename $(dirname "$task_file"))
progress_file=".claude/epics/${epic_name}/updates/$ARGUMENTS/progress.md"

if [ -f "$progress_file" ]; then
  # issue-sync was used, check completion
  current_completion=$(grep "^completion:" "$progress_file" 2>/dev/null | sed "s/completion: *//" | tr -d "%")

  if [ "$current_completion" -ge 100 ] && [ "$current_status" != "closed" ]; then
    echo "ℹ️ 任务通过 issue-sync 标记完成 (${current_completion}%)，正在执行关闭操作..."
    completion_source="issue-sync"
  elif [ "$current_status" = "closed" ]; then
    echo "⚠️ 任务已本地关闭，检查 GitHub 同步状态..."
    completion_source="already-closed"
  else
    echo "ℹ️ 基于 issue-sync 数据完成任务关闭..."
    completion_source="issue-sync-partial"
  fi
else
  # No issue-sync used, direct completion
  if [ "$current_status" = "closed" ]; then
    echo "⚠️ 任务已关闭，验证 GitHub 状态..."
    completion_source="already-closed"
  else
    echo "ℹ️ 直接完成并关闭任务 (未使用 issue-sync)..."
    completion_source="direct"
  fi
fi

# Export completion info for later use
echo "$completion_source" > /tmp/completion_source.txt
echo "$current_completion" > /tmp/current_completion.txt
echo "$progress_file" > /tmp/progress_file.txt
'
```

### 3. Update Local Status

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update task file frontmatter:
```yaml
status: closed
updated: {current_datetime}
```

### 4. Update Progress File (if exists)

If progress file exists, ensure completion is properly recorded:
```bash
bash -c '
current_datetime=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
progress_file=$(cat /tmp/progress_file.txt)

if [ -f "$progress_file" ]; then
  # Update progress file with final completion
  sed -i.bak "/^completion:/c\\completion: 100%" "$progress_file"
  sed -i.bak "/^last_sync:/c\\last_sync: $current_datetime" "$progress_file"
  rm "${progress_file}.bak"

  # Add completion note
  echo "" >> "$progress_file"
  echo "## ✅ Final Completion - $current_datetime" >> "$progress_file"
  echo "Task officially closed via /pm:issue-close" >> "$progress_file"
  if [ -n "'$2'" ]; then
    echo "Notes: '$2'" >> "$progress_file"
  fi
fi
'
```

### 5. Collect Related Commits

# Get commits related to this issue since task started
bash -c '
ARGUMENTS="'$ARGUMENTS'"
progress_file=$(cat /tmp/progress_file.txt)

if [ -f "$progress_file" ]; then
  start_date=$(grep "^started:" "$progress_file" | sed "s/started: *//")
else
  start_date="7 days ago" # fallback
fi

# Find related commits by issue number and timeframe
related_commits=$(git log --oneline --grep="#$ARGUMENTS" --since="$start_date")
if [ -z "$related_commits" ]; then
  related_commits=$(git log --oneline --since="$start_date" --author="$(git config user.name)" | head -5)
fi

# Export for later use
echo "$related_commits" > /tmp/related_commits.txt
'

### 6. Close on GitHub

Create comprehensive completion comment based on available information:
```bash
# Create completion comment content
cat > /tmp/completion-comment.md << EOF
## ✅ Task Completed - $(date -u +"%Y-%m-%dT%H:%M:%SZ")

### 📋 Completion Summary
EOF

# Add completion source information
case "$completion_source" in
  "issue-sync")
    cat >> /tmp/completion-comment.md << EOF
This task was tracked through issue-sync and marked complete at ${current_completion}%.
All acceptance criteria have been verified and deliverables completed.
EOF
    ;;
  "direct")
    cat >> /tmp/completion-comment.md << EOF
Task completed directly without issue-sync tracking.
Manual verification of completion criteria performed.
EOF
    ;;
  "already-closed")
    cat >> /tmp/completion-comment.md << EOF
Task was already marked complete locally. Synchronizing final closure to GitHub.
EOF
    ;;
esac

# Add completion notes if provided
if [ ! -z "$2" ]; then
  cat >> /tmp/completion-comment.md << EOF

### 📝 Completion Notes
$2
EOF
fi

# Add commits if found and post to GitHub
bash -c '
issue_number=$(cat /tmp/current_issue_number.txt)
completion_source=$(cat /tmp/completion_source.txt)
current_completion=$(cat /tmp/current_completion.txt)
related_commits=$(cat /tmp/related_commits.txt)

# Add commits if found
if [ -n "$related_commits" ]; then
  cat >> /tmp/completion-comment.md << EOF

### 💻 Related Commits
\`\`\`
$related_commits
\`\`\`
EOF
fi

cat >> /tmp/completion-comment.md << EOF

### 🎯 Status
- ✅ Task implementation complete
- ✅ Local files updated
- ✅ GitHub issue closed

This task is now complete and ready for epic integration.

---
*Closed via /pm:issue-close at $(date -u +"%Y-%m-%dT%H:%M:%SZ")*
EOF

# Post comment and close issue
gh issue comment $issue_number --body-file /tmp/completion-comment.md
gh issue close $issue_number
'
```

### 7. Update Epic Task List on GitHub

Check the task checkbox in the epic issue:

```bash
bash -c '
ARGUMENTS="'$ARGUMENTS'"
task_file=$(cat /tmp/current_task_file.txt)

# Extract epic name from task file path
epic_name=$(basename $(dirname "$task_file"))

# Get epic issue number from epic.md
epic_issue=$(grep "github_url:" .claude/epics/$epic_name/epic.md | grep -oE "[0-9]+$")

if [ -n "$epic_issue" ]; then
  # Get current epic body
  gh issue view $epic_issue --json body -q .body > /tmp/epic-body.md

  # Check off this task
  sed -i "s/- \\[ \\] #$ARGUMENTS/- [x] #$ARGUMENTS/" /tmp/epic-body.md

  # Update epic issue
  gh issue edit $epic_issue --body-file /tmp/epic-body.md

  echo "✓ Updated epic progress on GitHub"
  echo "$epic_name" > /tmp/current_epic_name.txt
else
  echo "⚠️ No epic issue found"
fi
'
```

### 8. Update Local Epic Task List

Update the "## Tasks Created" section in epic.md:
- Change `- [ ] {TASK_ID}` to `- [x] {TASK_ID} ✅` for completed task
- Add completion status indicator (✅)
- Maintain formatting consistency with other completed tasks

```bash
bash -c '
task_file=$(cat /tmp/current_task_file.txt)
epic_name=$(cat /tmp/current_epic_name.txt)

# Find the task ID from the local task file
task_id=$(basename "$task_file" .md)

# Update epic.md task list - handle both old and new formats
sed -i.bak "s/^- \\[ \\] ${task_id}\\(.*\\)$/- [x] ${task_id}\\1 ✅/" .claude/epics/$epic_name/epic.md

# Clean up duplicate ✅ if task was already marked
sed -i.bak "s/✅ ✅$/✅/" .claude/epics/$epic_name/epic.md
rm .claude/epics/$epic_name/epic.md.bak

echo "✓ Updated local epic task list for ${task_id}"
echo "$task_id" > /tmp/current_task_id.txt
'
```

### 9. Update Epic Progress (Comprehensive Calculation)

Calculate and update epic progress based on all task statuses:
```bash
bash -c '
epic_name=$(cat /tmp/current_epic_name.txt)

# Count total tasks in epic directory
total_tasks=$(ls .claude/epics/$epic_name/[A-Z][A-Z][A-Z][0-9][0-9][0-9].md 2>/dev/null | wc -l)

# Count completed tasks (both file status and epic.md checkboxes)
closed_by_status=$(grep -l "^status: closed" .claude/epics/$epic_name/[A-Z][A-Z][A-Z][0-9][0-9][0-9].md 2>/dev/null | wc -l)
checked_in_epic=$(grep -c "- \\[x\\]" .claude/epics/$epic_name/epic.md 2>/dev/null || echo 0)

# Use the higher count (more accurate representation)
if [ "$closed_by_status" -gt "$checked_in_epic" ]; then
  closed_tasks=$closed_by_status
else
  closed_tasks=$checked_in_epic
fi

# Calculate progress percentage
if [ "$total_tasks" -gt 0 ]; then
  epic_progress=$(( (closed_tasks * 100) / total_tasks ))

  # Update epic.md frontmatter
  current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  sed -i.bak "/^progress:/c\\progress: ${epic_progress}%" .claude/epics/$epic_name/epic.md
  sed -i.bak "/^updated:/c\\updated: $current_date" .claude/epics/$epic_name/epic.md
  rm .claude/epics/$epic_name/epic.md.bak

  echo "✓ Epic progress updated: ${epic_progress}% (${closed_tasks}/${total_tasks} tasks complete)"

  # Export for final output
  echo "$epic_progress" > /tmp/epic_progress.txt
  echo "$closed_tasks" > /tmp/closed_tasks.txt
  echo "$total_tasks" > /tmp/total_tasks.txt
else
  echo "⚠️ No tasks found for epic progress calculation"
fi
'
```

### 10. Output

Provide comprehensive completion summary:
```bash
bash -c '
ARGUMENTS="'$ARGUMENTS'"
issue_number=$(cat /tmp/current_issue_number.txt)
completion_source=$(cat /tmp/completion_source.txt)
current_completion=$(cat /tmp/current_completion.txt)
epic_name=$(cat /tmp/current_epic_name.txt)
epic_progress=$(cat /tmp/epic_progress.txt)
closed_tasks=$(cat /tmp/closed_tasks.txt)
total_tasks=$(cat /tmp/total_tasks.txt)

echo "✅ Closed issue #$ARGUMENTS"
echo ""
echo "📋 Completion Summary:"
echo "  Source: $completion_source"
echo "  Local: Task marked complete"
echo "  GitHub: Issue closed & epic updated"
echo "  Epic progress: ${epic_progress}% (${closed_tasks}/${total_tasks} tasks complete)"
echo ""

if [ "$completion_source" = "issue-sync" ]; then
  echo "📊 Progress was tracked via issue-sync (${current_completion}%)"
elif [ "$completion_source" = "direct" ]; then
  echo "📝 Direct completion (no issue-sync used)"
fi

echo ""
echo "🔗 Next actions:"
echo "  View closed issue: gh issue view $issue_number"
echo "  Epic status: /pm:epic-status $epic_name"
echo "  Next task: /pm:next"
'
```

## Important Notes

Follow `/rules/frontmatter-operations.md` for updates.
Follow `/rules/github-operations.md` for GitHub commands.
Always sync local state before GitHub.