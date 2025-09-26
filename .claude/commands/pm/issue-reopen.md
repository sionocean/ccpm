---
allowed-tools: Bash, Read, Write, LS
---

# Issue Reopen

Reopen a closed issue.

## Usage
```
/pm:issue-reopen <task_id> [reason]
```

## Instructions

### 1. Find Local Task File and Extract GitHub Issue Number

```bash
# Find task file
find .claude/epics -name "$ARGUMENTS.md" -not -path "*/.archived/*" 2>/dev/null > /tmp/task-files.txt
task_file=$(head -1 /tmp/task-files.txt 2>/dev/null)
if [ -z "$task_file" ]; then
  echo "❌ No task file found for $ARGUMENTS"
  exit 1
fi

# Extract GitHub issue number from task file
github_url=$(grep "^github_url:" "$task_file" 2>/dev/null)
issue_number=$(echo "$github_url" | sed 's|.*/||')
if [ -z "$issue_number" ]; then
  echo "❌ No GitHub issue found for $ARGUMENTS. Run /pm:epic-sync first."
  exit 1
fi
```

### 2. Update Local Status

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Update task file frontmatter:
```yaml
status: open
updated: {current_datetime}
```

### 3. Reset Progress

If progress file exists:
- Keep original started date
- Reset completion to previous value or 0%
- Add note about reopening with reason

### 4. Reopen on GitHub

```bash
# Reopen with comment
echo "🔄 Reopening issue

Reason: $ARGUMENTS

---
Reopened at: {timestamp}" | gh issue comment $issue_number --body-file -

# Reopen the issue
gh issue reopen $issue_number
```

### 5. Update Epic Progress

Recalculate epic progress with this task now open again.

### 6. Output

```
🔄 Reopened issue #$ARGUMENTS
  Reason: {reason_if_provided}
  Epic progress: {updated_progress}%
  
Start work with: /pm:issue-start $ARGUMENTS
```

## Important Notes

Preserve work history in progress files.
Don't delete previous progress, just reset status.