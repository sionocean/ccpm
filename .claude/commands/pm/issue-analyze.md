---
allowed-tools: Bash, Read, Write, LS
---

# Issue Analyze

Analyze an issue to identify parallel work streams for maximum efficiency while preserving task implementation details.

## Usage
```
/pm:issue-analyze <task_id>
```

## Required Rules

**IMPORTANT:** Before executing this command, read and follow:
- `.claude/rules/detail-preservation.md` - For maintaining task implementation details in work streams

## Quick Check

1. **Find local task file:**
   ```bash
   bash -c '
   ARGUMENTS="'$ARGUMENTS'"
   # Find task file
   find .claude/epics -name "$ARGUMENTS.md" -not -path "*/.archived/*" 2>/dev/null > /tmp/task-files.txt
   task_file=$(head -1 /tmp/task-files.txt 2>/dev/null)
   if [ -z "$task_file" ]; then
     echo "❌ No task file found for $ARGUMENTS. Run: /pm:import first"
     exit 1
   fi
   echo "✅ Found task file: $task_file"
   # Export for later use
   echo "$task_file" > /tmp/current_task_file.txt
   '
   ```

2. **Check for existing analysis:**
   ```bash
   bash -c '
   ARGUMENTS="'$ARGUMENTS'"
   task_file=$(cat /tmp/current_task_file.txt)
   epic_dir=$(dirname "$task_file")
   if [ -f "$epic_dir/$ARGUMENTS-analysis.md" ]; then
     echo "⚠️ Analysis already exists: $epic_dir/$ARGUMENTS-analysis.md"
     echo "Will overwrite existing analysis"
   fi
   echo "$epic_dir" > /tmp/current_epic_dir.txt
   '
   ```

## Instructions

### 1. Read and Extract Task Details

Get issue details from GitHub:
```bash
bash -c '
ARGUMENTS="'$ARGUMENTS'"
task_file=$(cat /tmp/current_task_file.txt)

# Extract GitHub issue number from task file
github_url=$(grep "^github_url:" "$task_file" 2>/dev/null)
issue_number=$(echo "$github_url" | sed "s|.*/||")
if [ -z "$issue_number" ]; then
  echo "❌ No GitHub issue found for $ARGUMENTS. Run /pm:epic-sync first."
  exit 1
fi

echo "✅ Found GitHub issue: #$issue_number"
gh issue view $issue_number --json title,body,labels

# Export for later use
echo "$issue_number" > /tmp/current_issue_number.txt
echo "$github_url" > /tmp/current_github_url.txt
'
```

Read local task file to understand and **preserve ALL specific requirements**:
- **Extract complete technical requirements** - Every API, component, function, integration specified
- **Catalog all acceptance criteria** - Every specific behavior, validation rule, UI requirement
- **Document all dependencies** - Technical, business, and external dependencies
- **Preserve implementation details** - Specific approaches, patterns, frameworks mentioned
- Effort estimate and complexity factors

### 2. Identify Parallel Work Streams (Think Harder)

**Use enhanced reasoning to analyze optimal work stream breakdown:**

Think harder: Analyze the specific technical requirements to identify the most efficient parallel execution strategy while preserving all implementation details.

Analyze the issue to identify independent work that can run in parallel:

**Common Patterns:**
- **Database Layer**: Schema, migrations, models
- **Service Layer**: Business logic, data access
- **API Layer**: Endpoints, validation, middleware
- **UI Layer**: Components, pages, styles
- **Test Layer**: Unit tests, integration tests
- **Documentation**: API docs, README updates

**Key Questions:**
- What specific files will be created/modified?
- Which specific changes can happen independently?
- What are the detailed dependencies between changes?
- Where might conflicts occur at the file/function level?
- **Detail preservation**: How to maintain specific requirements in each stream?

### 3. Create Analysis File

Get current datetime: `date -u +"%Y-%m-%dT%H:%M:%SZ"`

Create `.claude/epics/{epic_name}/$ARGUMENTS-analysis.md`:

```markdown
---
issue: $ARGUMENTS
title: {issue_title}
analyzed: {current_datetime}
estimated_hours: {total_hours}
parallelization_factor: {1.0-5.0}
---

# Parallel Work Analysis: Issue #$ARGUMENTS

## Overview
{Brief description of what needs to be done}

## Parallel Streams

### Stream A: {Stream Name}
**Scope**: {What this stream handles - maintain specific technical requirements}
**Specific Requirements**: {List detailed requirements from task - APIs, components, validations, etc.}
**Files**:
- {file_pattern_1}
- {file_pattern_2}
**Agent Type**: {backend|frontend|fullstack|database}-specialist
**Can Start**: immediately
**Estimated Hours**: {hours}
**Dependencies**: none

### Stream B: {Stream Name}
**Scope**: {What this stream handles - maintain specific technical requirements}
**Specific Requirements**: {List detailed requirements from task - APIs, components, validations, etc.}
**Files**:
- {file_pattern_1}
- {file_pattern_2}
**Agent Type**: {agent_type}
**Can Start**: immediately
**Estimated Hours**: {hours}
**Dependencies**: none

### Stream C: {Stream Name}
**Scope**: {What this stream handles - maintain specific technical requirements}
**Specific Requirements**: {List detailed requirements from task - APIs, components, validations, etc.}
**Files**:
- {file_pattern_1}
**Agent Type**: {agent_type}
**Can Start**: after Stream A completes
**Estimated Hours**: {hours}
**Dependencies**: Stream A

## Coordination Points

### Shared Files
{List any files multiple streams need to modify}:
- `src/types/index.ts` - Streams A & B (coordinate type updates)
- `package.json` - Stream B (add dependencies)

### Sequential Requirements
{List what must happen in order}:
1. Database schema before API endpoints
2. API types before UI components
3. Core logic before tests

## Conflict Risk Assessment
- **Low Risk**: Streams work on different directories
- **Medium Risk**: Some shared type files, manageable with coordination
- **High Risk**: Multiple streams modifying same core files

## Parallelization Strategy

**Recommended Approach**: {sequential|parallel|hybrid}

{If parallel}: Launch Streams A, B simultaneously. Start C when A completes.
{If sequential}: Complete Stream A, then B, then C.
{If hybrid}: Start A & B together, C depends on A, D depends on B & C.

## Expected Timeline

With parallel execution:
- Wall time: {max_stream_hours} hours
- Total work: {sum_all_hours} hours
- Efficiency gain: {percentage}%

Without parallel execution:
- Wall time: {sum_all_hours} hours

## Notes
{Any special considerations, warnings, or recommendations}
```

### 4. Validate Analysis

Ensure:
- **Detail preservation check** - Each stream contains specific task requirements, not generalized descriptions
- **Complete requirement mapping** - Every task requirement is assigned to a specific stream
- **No simplification** - Stream descriptions maintain same detail level as original task
- All major work is covered by streams
- File patterns don't unnecessarily overlap
- Dependencies are logical
- Agent types match the work type
- Time estimates are reasonable

### 5. Output

```
✅ Analysis complete for issue #$ARGUMENTS

Identified {count} parallel work streams:
  Stream A: {name} ({hours}h)
  Stream B: {name} ({hours}h)
  Stream C: {name} ({hours}h)
  
Parallelization potential: {factor}x speedup
  Sequential time: {total}h
  Parallel time: {reduced}h

Files at risk of conflict:
  {list shared files if any}

Next: Start work with /pm:issue-start $ARGUMENTS
```

## Important Notes

- Analysis is local only - not synced to GitHub
- Focus on practical parallelization, not theoretical maximum
- Consider agent expertise when assigning streams
- Account for coordination overhead in estimates
- Prefer clear separation over maximum parallelization