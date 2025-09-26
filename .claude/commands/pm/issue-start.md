---
allowed-tools: Bash, Read, Write, LS, Task
---

# Issue Start

Begin work on a GitHub issue with parallel agents based on work stream analysis.

## Usage
```
/pm:issue-start <task_id>
```

## Quick Check

1. **Get issue details:**
   ```bash
   bash -c '
   ARGUMENTS="'$ARGUMENTS'"
   # Find task file
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

   echo "✅ Found task file: $task_file"
   echo "✅ GitHub issue: #$issue_number"
   gh issue view $issue_number --json state,title,labels,body

   # Export for later use
   echo "$task_file" > /tmp/current_task_file.txt
   echo "$issue_number" > /tmp/current_issue_number.txt
   '
   ```
   If it fails: "❌ Cannot access issue #$issue_number. Check number or run: gh auth login"

2. **Find local task file:**
   - Check if task file exists (already done in step 1)
   - If not found: "❌ No local task for issue $ARGUMENTS. This task may have been created outside the PM system."

3. **Check for analysis:**
   ```bash
   bash -c '
   ARGUMENTS="'$ARGUMENTS'"
   task_file=$(cat /tmp/current_task_file.txt)
   epic_dir=$(dirname "$task_file")

   if [ -f "$epic_dir/$ARGUMENTS-analysis.md" ]; then
     echo "✅ Found analysis file: $epic_dir/$ARGUMENTS-analysis.md"
     echo "$epic_dir" > /tmp/current_epic_dir.txt
   else
     echo "❌ No analysis found for issue #$ARGUMENTS"
     echo ""
     echo "Run: /pm:issue-analyze $ARGUMENTS first"
     echo "Or: /pm:issue-start $ARGUMENTS --analyze to do both"
     exit 1
   fi
   '
   ```
   If no analysis exists and no --analyze flag, stop execution.

## Instructions

### 1. Ensure Worktree Exists

Check if epic worktree exists:
```bash
bash -c '
task_file=$(cat /tmp/current_task_file.txt)

# Extract epic name from task file path
epic_name=$(basename $(dirname "$task_file"))

# Check worktree
git worktree list > /tmp/worktrees.txt
if grep -q "epic/$epic_name" /tmp/worktrees.txt; then
  echo "✅ Worktree exists for epic: epic/$epic_name"
  grep "epic/$epic_name" /tmp/worktrees.txt
  echo "$epic_name" > /tmp/current_epic_name.txt
else
  echo "❌ No worktree for epic. Run: /pm:epic-start $epic_name"
  exit 1
fi
'
```

### 2. Read Analysis

Read `.claude/epics/{epic_name}/$ARGUMENTS-analysis.md`:
- Parse parallel streams
- Identify which can start immediately
- Note dependencies between streams

### 3. Setup Progress Tracking

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Create workspace structure:
```bash
bash -c '
ARGUMENTS="'$ARGUMENTS'"
epic_name=$(cat /tmp/current_epic_name.txt)
mkdir -p .claude/epics/${epic_name}/updates/$ARGUMENTS
echo "✅ Created workspace: .claude/epics/${epic_name}/updates/$ARGUMENTS"
'
```

Update task file frontmatter `updated` field with current datetime.

### 4. GitHub Assignment

```bash
bash -c '
issue_number=$(cat /tmp/current_issue_number.txt)

# Assign to self and mark in-progress
gh issue edit $issue_number --add-assignee @me
echo "✅ Assigned issue #$issue_number to self"
'
```

### 5. Launch Parallel Agents

For each stream that can start immediately:

Create `.claude/epics/{epic_name}/updates/$ARGUMENTS/stream-{X}.md`:
```markdown
---
issue: $ARGUMENTS
stream: {stream_name}
agent: {agent_type}
started: {current_datetime}
status: in_progress
---

# Stream {X}: {stream_name}

## Scope
{stream_description}

## Files
{file_patterns}

## Progress
- Starting implementation
```

Launch agent using Task tool:
```yaml
Task:
  description: "Issue #$ARGUMENTS Stream {X}"
  subagent_type: "{agent_type}"
  prompt: |
    You are working on Issue #$ARGUMENTS in the epic worktree.
    
    Worktree location: ../epic/{epic_name}/
    Your stream: {stream_name}
    
    Your scope:
    - Files to modify: {file_patterns}
    - Work to complete: {stream_description}
    
    Requirements:
    1. Read full task from: .claude/epics/{epic_name}/{task_file}
    2. Work ONLY in your assigned files
    3. Commit frequently with format: "Issue #$ARGUMENTS: {specific change}"
    4. Update progress in: .claude/epics/{epic_name}/updates/$ARGUMENTS/stream-{X}.md
    5. Follow coordination rules in /rules/agent-coordination.md
    
    If you need to modify files outside your scope:
    - Check if another stream owns them
    - Wait if necessary
    - Update your progress file with coordination notes
    
    Complete your stream's work and mark as completed when done.
```

### 6. Output

```
✅ Started parallel work on issue #$ARGUMENTS

Epic: {epic_name}
Worktree: ../epic/{epic_name}/

Launching {count} parallel agents:
  Stream A: {name} (Agent-1) ✓ Started
  Stream B: {name} (Agent-2) ✓ Started
  Stream C: {name} - Waiting (depends on A)

Progress tracking:
  .claude/epics/{epic_name}/updates/$ARGUMENTS/

Monitor with: /pm:epic-status {epic_name}
Sync updates: /pm:issue-sync $ARGUMENTS
```

## Error Handling

If any step fails, report clearly:
- "❌ {What failed}: {How to fix}"
- Continue with what's possible
- Never leave partial state

## Important Notes

Follow `/rules/datetime.md` for timestamps.
Keep it simple - trust that GitHub and file system work.