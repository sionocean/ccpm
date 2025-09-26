---
allowed-tools: Bash, Read, Write, LS, Task
---

# Epic Sync

Push epic and tasks to GitHub as issues while preserving Epic-prefixed task IDs.

## Usage
```
/pm:epic-sync <feature_name>
```

## Quick Check

```bash
# Verify epic exists
test -f .claude/epics/$ARGUMENTS/epic.md || echo "❌ Epic not found. Run: /pm:prd-parse $ARGUMENTS"

# Count Epic-prefixed task files
ls .claude/epics/$ARGUMENTS/*.md 2>/dev/null | grep -v epic.md | wc -l
```

If no tasks found: "❌ No tasks to sync. Run: /pm:epic-decompose $ARGUMENTS"

## Instructions

### 0. Check Remote Repository

Follow `/rules/github-operations.md` to ensure we're not syncing to the CCPM template:

```bash
# Check if remote origin is the CCPM template repository
remote_url=$(git remote get-url origin 2>/dev/null || echo "")
if [[ "$remote_url" == *"automazeio/ccpm"* ]] || [[ "$remote_url" == *"automazeio/ccpm.git"* ]]; then
  echo "❌ ERROR: You're trying to sync with the CCPM template repository!"
  echo ""
  echo "This repository (automazeio/ccpm) is a template for others to use."
  echo "You should NOT create issues or PRs here."
  echo ""
  echo "To fix this:"
  echo "1. Fork this repository to your own GitHub account"
  echo "2. Update your remote origin:"
  echo "   git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
  echo ""
  echo "Or if this is a new project:"
  echo "1. Create a new repository on GitHub"
  echo "2. Update your remote origin:"
  echo "   git remote set-url origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
  echo ""
  echo "Current remote: $remote_url"
  exit 1
fi
```

### 1. Create Epic Issue

Strip frontmatter and prepare GitHub issue body:
```bash
# Extract content without frontmatter
sed '1,/^---$/d; 1,/^---$/d' .claude/epics/$ARGUMENTS/epic.md > /tmp/epic-body-raw.md

# Remove "## Tasks Created" section and replace with Stats
awk '
  /^## Tasks Created/ {
    in_tasks=1
    next
  }
  /^## / && in_tasks {
    in_tasks=0
    # When we hit the next section after Tasks Created, add Stats
    if (total_tasks) {
      print "## Stats\n"
      print "Total tasks: " total_tasks
      print "Parallel tasks: " parallel_tasks " (can be worked on simultaneously)"
      print "Sequential tasks: " sequential_tasks " (have dependencies)"
      if (total_effort) print "Estimated total effort: " total_effort " hours"
      print ""
    }
  }
  /^Total tasks:/ && in_tasks { total_tasks = $3; next }
  /^Parallel tasks:/ && in_tasks { parallel_tasks = $3; next }
  /^Sequential tasks:/ && in_tasks { sequential_tasks = $3; next }
  /^Estimated total effort:/ && in_tasks {
    gsub(/^Estimated total effort: /, "")
    total_effort = $0
    next
  }
  !in_tasks { print }
  END {
    # If we were still in tasks section at EOF, add stats
    if (in_tasks && total_tasks) {
      print "## Stats\n"
      print "Total tasks: " total_tasks
      print "Parallel tasks: " parallel_tasks " (can be worked on simultaneously)"
      print "Sequential tasks: " sequential_tasks " (have dependencies)"
      if (total_effort) print "Estimated total effort: " total_effort
    }
  }
' /tmp/epic-body-raw.md > /tmp/epic-body.md

# Determine epic type (feature vs bug) from content
if grep -qi "bug\|fix\|issue\|problem\|error" /tmp/epic-body.md; then
  epic_type="bug"
else
  epic_type="feature"
fi

# Create epic issue with labels
epic_number=$(gh issue create \
  --title "Epic: $ARGUMENTS" \
  --body-file /tmp/epic-body.md \
  --label "epic,epic:$ARGUMENTS,$epic_type" \
  --json url -q .url | xargs basename)
```

Store the returned issue number for epic frontmatter update.

### 2. Create Task Sub-Issues

Check if gh-sub-issue is available:
```bash
if gh extension list | grep -q "yahsan2/gh-sub-issue"; then
  use_subissues=true
else
  use_subissues=false
  echo "⚠️ gh-sub-issue not installed. Using fallback mode."
fi
```

Count Epic-prefixed task files to determine strategy:
```bash
task_count=$(ls .claude/epics/$ARGUMENTS/[A-Z][A-Z][A-Z][0-9][0-9][0-9].md 2>/dev/null | wc -l)
```

### For Small Batches (< 5 tasks): Sequential Creation

```bash
if [ "$task_count" -lt 5 ]; then
  # Create sequentially for small batches
  for task_file in .claude/epics/$ARGUMENTS/[A-Z][A-Z][A-Z][0-9][0-9][0-9].md; do
    [ -f "$task_file" ] || continue

    # Extract task title from frontmatter
    task_name=$(grep '^title:' "$task_file" | sed 's/^title: *//')

    # Strip frontmatter from task content
    sed '1,/^---$/d; 1,/^---$/d' "$task_file" > /tmp/task-body.md

    # Create sub-issue with labels
    if [ "$use_subissues" = true ]; then
      task_number=$(gh sub-issue create \
        --parent "$epic_number" \
        --title "$task_name" \
        --body "$(cat /tmp/task-body.md)" \
        --label "task,epic:$ARGUMENTS" \
        --json number -q .number)
    else
      task_number=$(gh issue create \
        --title "$task_name" \
        --body-file /tmp/task-body.md \
        --label "task,epic:$ARGUMENTS" \
        --json number -q .number)
    fi

    # Record mapping (but keep Epic-prefixed filenames)
    echo "$task_file:$task_number" >> /tmp/task-mapping.txt
  done

  # After creating all issues, update GitHub URLs in frontmatter
  # DO NOT rename files - keep Epic-prefixed names
fi
```

### For Larger Batches: Parallel Creation

```bash
if [ "$task_count" -ge 5 ]; then
  echo "Creating $task_count sub-issues in parallel..."

  # Check if gh-sub-issue is available for parallel agents
  if gh extension list | grep -q "yahsan2/gh-sub-issue"; then
    subissue_cmd="gh sub-issue create --parent $epic_number"
  else
    subissue_cmd="gh issue create"
  fi

  # Batch tasks for parallel processing
  # Spawn agents to create sub-issues in parallel with proper labels
  # Each agent must use: --label "task,epic:$ARGUMENTS"
fi
```

Use Task tool for parallel creation:
```yaml
Task:
  description: "Create GitHub sub-issues batch {X}"
  subagent_type: "general-purpose"
  prompt: |
    Create GitHub sub-issues for tasks in epic $ARGUMENTS
    Parent epic issue: #$epic_number

    Tasks to process:
    - {list of 3-4 task files}

    For each task file:
    1. Extract task name from frontmatter
    2. Strip frontmatter using: sed '1,/^---$/d; 1,/^---$/d'
    3. Create sub-issue using:
       - If gh-sub-issue available:
         gh sub-issue create --parent $epic_number --title "$task_name" \
           --body-file /tmp/task-body.md --label "task,epic:$ARGUMENTS"
       - Otherwise:
         gh issue create --title "$task_name" --body-file /tmp/task-body.md \
           --label "task,epic:$ARGUMENTS"
    4. Record: task_file:issue_number

    IMPORTANT: Always include --label parameter with "task,epic:$ARGUMENTS"

    Return mapping of files to issue numbers.
```

Consolidate results from parallel agents:
```bash
# Collect all mappings from agents
cat /tmp/batch-*/mapping.txt >> /tmp/task-mapping.txt

# Verify mapping correctness (solve parallel creation race condition)
echo "🔍 Verifying issue mapping..."

created_issues=$(cat /tmp/batch-*/mapping.txt | cut -d: -f2)
> /tmp/verified-mapping.txt

for issue_num in $created_issues; do
  # Extract task_id from issue title
  task_id=$(gh issue view $issue_num --json title -q .title | grep -o '^[A-Z][A-Z][A-Z][0-9][0-9][0-9]')

  if [[ -n "$task_id" ]]; then
    task_file=".claude/epics/$ARGUMENTS/${task_id}.md"
    if [[ -f "$task_file" ]]; then
      echo "$task_file:$issue_num" >> /tmp/verified-mapping.txt
      echo "✅ $task_id → #$issue_num (verified)"
    else
      echo "⚠️  No local file found for $task_id"
    fi
  else
    echo "⚠️  Could not extract task ID from issue #$issue_num"
  fi
done

# Replace with verified mapping
mv /tmp/verified-mapping.txt /tmp/task-mapping.txt

# IMPORTANT: After verification, follow step 3 to:
# 1. Build old->new ID mapping
# 2. Update all task references (depends_on, conflicts_with)
# 3. Rename files with proper frontmatter updates
```

### 3. Update Task Files with GitHub URLs

**IMPORTANT: Keep Epic-prefixed filenames, only update frontmatter**

```bash
# Process each task file - DO NOT rename files
while IFS=: read -r task_file task_number; do
  # Keep the Epic-prefixed filename (e.g., ABC001.md)
  # Only update GitHub URL in frontmatter
  
  repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  github_url="https://github.com/$repo/issues/$task_number"
  current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  # Update frontmatter with GitHub URL and timestamp
  sed -i.bak "/^github_url:/c\github_url: $github_url" "$task_file"
  sed -i.bak "/^updated:/c\updated: $current_date" "$task_file"
  rm "${task_file}.bak"
  
  echo "Updated $(basename "$task_file") → GitHub Issue #$task_number"
done < /tmp/task-mapping.txt
```

### 4. Update Epic with Task List (Fallback Only)

If NOT using gh-sub-issue, add task list to epic:

```bash
if [ "$use_subissues" = false ]; then
  # Get current epic body
  gh issue view {epic_number} --json body -q .body > /tmp/epic-body.md

  # Append task list
  cat >> /tmp/epic-body.md << 'EOF'

  ## Tasks
  - [ ] #{task1_number} {task1_name}
  - [ ] #{task2_number} {task2_name}
  - [ ] #{task3_number} {task3_name}
  EOF

  # Update epic issue
  gh issue edit {epic_number} --body-file /tmp/epic-body.md
fi
```

With gh-sub-issue, this is automatic!

### 5. Update Epic File

Update the epic file with GitHub URL, timestamp, and real task IDs:

#### 5a. Update Frontmatter
```bash
# Get repo info
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
epic_url="https://github.com/$repo/issues/$epic_number"
current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Update epic frontmatter
sed -i.bak "/^github_url:/c\github_url: $epic_url" .claude/epics/$ARGUMENTS/epic.md
sed -i.bak "/^updated:/c\updated: $current_date" .claude/epics/$ARGUMENTS/epic.md
rm .claude/epics/$ARGUMENTS/epic.md.bak
```

#### 5b. Update Tasks Created Section
```bash
# Create a temporary file with the updated Tasks Created section
cat > /tmp/tasks-section.md << 'EOF'
## Tasks Created
EOF

# Add each task with Epic ID and GitHub issue mapping
for task_file in .claude/epics/$ARGUMENTS/[A-Z][A-Z][A-Z][0-9][0-9][0-9].md; do
  [ -f "$task_file" ] || continue

  # Get Epic task ID from frontmatter
  epic_task_id=$(grep '^id:' "$task_file" | sed 's/^id: *["']\?\([^"']*\)["']\?.*/\1/')
  
  # Get GitHub issue number from frontmatter
  github_url=$(grep '^github_url:' "$task_file" | sed 's/^github_url: *//')
  issue_num=$(echo "$github_url" | sed 's|.*/||')

  # Get task name from frontmatter
  task_name=$(grep '^title:' "$task_file" | sed 's/^title: *//')

  # Get parallel status
  parallel=$(grep '^parallel:' "$task_file" | sed 's/^parallel: *//')

  # Add to tasks section with Epic ID mapping
  echo "- [ ] ${epic_task_id} → #${issue_num} - ${task_name} (parallel: ${parallel})" >> /tmp/tasks-section.md
done

# Add summary statistics
total_count=$(ls .claude/epics/$ARGUMENTS/[A-Z][A-Z][A-Z][0-9][0-9][0-9].md 2>/dev/null | wc -l)
parallel_count=$(grep -l '^parallel: true' .claude/epics/$ARGUMENTS/[A-Z][A-Z][A-Z][0-9][0-9][0-9].md 2>/dev/null | wc -l)
sequential_count=$((total_count - parallel_count))

cat >> /tmp/tasks-section.md << EOF

Total tasks: ${total_count}
Parallel tasks: ${parallel_count}
Sequential tasks: ${sequential_count}
EOF

# Replace the Tasks Created section in epic.md
# First, create a backup
cp .claude/epics/$ARGUMENTS/epic.md .claude/epics/$ARGUMENTS/epic.md.backup

# Use awk to replace the section
awk '
  /^## Tasks Created/ {
    skip=1
    while ((getline line < "/tmp/tasks-section.md") > 0) print line
    close("/tmp/tasks-section.md")
  }
  /^## / && !/^## Tasks Created/ { skip=0 }
  !skip && !/^## Tasks Created/ { print }
' .claude/epics/$ARGUMENTS/epic.md.backup > .claude/epics/$ARGUMENTS/epic.md

# Clean up
rm .claude/epics/$ARGUMENTS/epic.md.backup
rm /tmp/tasks-section.md
```

### 6. Create Mapping File

Create `.claude/epics/$ARGUMENTS/github-mapping.md`:
```bash
# Create mapping file with Epic-to-GitHub mapping
cat > .claude/epics/$ARGUMENTS/github-mapping.md << EOF
# Epic ABC (${ARGUMENTS}) GitHub Mapping

Epic: #${epic_number} - https://github.com/${repo}/issues/${epic_number}

Epic Task → GitHub Issue
EOF

# Add each task mapping
for task_file in .claude/epics/$ARGUMENTS/[A-Z][A-Z][A-Z][0-9][0-9][0-9].md; do
  [ -f "$task_file" ] || continue

  epic_task_id=$(grep '^id:' "$task_file" | sed 's/^id: *["']\?\([^"']*\)["']\?.*/\1/')
  task_name=$(grep '^title:' "$task_file" | sed 's/^title: *//')
  github_url=$(grep '^github_url:' "$task_file" | sed 's/^github_url: *//')
  issue_num=$(echo "$github_url" | sed 's|.*/||')

  echo "- ${epic_task_id}.md → #${issue_num}: ${task_name}" >> .claude/epics/$ARGUMENTS/github-mapping.md
done

# Add sync timestamp
echo "" >> .claude/epics/$ARGUMENTS/github-mapping.md
echo "Synced: $(date -u +"%Y-%m-%dT%H:%M:%SZ")" >> .claude/epics/$ARGUMENTS/github-mapping.md
```

### 7. Create Epic Branch and Worktree

Follow `/rules/branch-operations.md` and `/rules/worktree-operations.md`:

```bash
# Record current branch as source branch
current_branch=$(git branch --show-current)

# Update epic.md frontmatter to include source branch
if grep -q '^source_branch:' .claude/epics/$ARGUMENTS/epic.md; then
  sed -i.bak "s/^source_branch:.*/source_branch: $current_branch/" .claude/epics/$ARGUMENTS/epic.md
else
  # Add source_branch after the status line
  sed -i.bak "/^status:/a\
source_branch: $current_branch" .claude/epics/$ARGUMENTS/epic.md
fi
rm -f .claude/epics/$ARGUMENTS/epic.md.bak

# Create epic branch from current branch
git checkout -b epic/$ARGUMENTS
git push -u origin epic/$ARGUMENTS

# Create worktree from epic branch
git worktree add ../epic/$ARGUMENTS

echo "✅ Created epic branch and worktree: ../epic/$ARGUMENTS from $current_branch"
```

### 8. Output

```
✅ Synced to GitHub
  - Epic: #{epic_number} - {epic_title}
  - Tasks: {count} sub-issues created
  - Labels applied: epic, task, epic:{name}
  - Files preserved: ABC001.md format maintained
  - GitHub URLs updated: frontmatter contains GitHub issue links
  - Epic dependencies preserved: depends_on/conflicts_with use Epic IDs
  - Worktree: ../epic/$ARGUMENTS

Next steps:
  - Start parallel execution: /pm:epic-start $ARGUMENTS
  - Or work on single issue: /pm:issue-start {issue_number}
  - View epic: https://github.com/{owner}/{repo}/issues/{epic_number}
```

## Error Handling

Follow `/rules/github-operations.md` for GitHub CLI errors.

If any issue creation fails:
- Report what succeeded  
- Note what failed
- Don't attempt rollback (partial sync is fine)
- Epic-prefixed files remain intact

## Important Notes

- Trust GitHub CLI authentication
- Don't pre-check for duplicates
- Update frontmatter only after successful creation
- Keep Epic-prefixed filenames intact (ABC001.md format)
- GitHub issue numbers only used for external linking
- Epic task IDs remain stable for dependency management
