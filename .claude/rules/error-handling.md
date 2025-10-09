# Error Handling Constraints

> **Status**: Permanent Development Constraints
> **Last Updated**: 2025-10-04
> **Audience**: Claude Code AI Agents
> **Language**: English

---

## Core Principle: Zero Freeze (零卡死)

**ABSOLUTE RULE**: No error shall ever cause application freeze, white screen, or hung loading state.

Every error must be:
1. **Caught** - No uncaught exceptions
2. **Standardized** - Converted to AppError format
3. **Handled** - Processed through unified error handling
4. **Communicated** - Displayed to user via Toast/Dialog
5. **Recovered** - Application returns to usable state

---

## Mandatory Practices

### 1. Never Use alert()

**FORBIDDEN**: `alert()`, `confirm()`, `prompt()` or any blocking browser dialogs.

**REASON**: Blocking dialogs freeze the entire application and violate Zero Freeze principle.

**REQUIRED**: Use `notificationService` for all user-facing error messages.

---

### 2. Always Use handleError()

**MANDATORY**: Every catch block must call `handleError(error, context)`.

**NEVER**:
- Silent catch blocks
- Console-only error logging
- Custom error display logic

**REQUIRED**: Unified error handling through `handleError()` ensures:
- Consistent error code mapping
- Automatic notification dispatch
- Proper logging and tracking
- Loading state management

---

### 3. Always Unlock Loading States

**CRITICAL**: Every loading state must be unlocked in error scenarios.

**PATTERN**:
- Set loading state in try block
- Unlock loading state in catch block BEFORE handleError()
- Never rely on finally block alone

**CONSEQUENCE OF VIOLATION**: Hung loading spinners freeze user interaction.

---

### 4. Always Provide Context

**MANDATORY**: `handleError()` requires context object with:
- `feature`: Business domain (e.g., 'auth', 'conversation')
- `action`: Operation being performed (e.g., 'login', 'create')
- `userId` (optional): For user-specific tracking

**REASON**: Context enables:
- Targeted error tracking
- Feature-specific error handling
- Better debugging and monitoring

---

## Four-Layer Architecture Responsibilities

### Layer 1: Network Layer (Axios Client)
**Responsibility**: Convert HTTP failures to standardized errors

**MUST**:
- Implement request timeout (15 seconds)
- Support AbortController for cancellation
- Map HTTP status codes to error codes
- Preserve original error details

**MUST NOT**:
- Display errors directly
- Implement retry logic (handled by caller)
- Modify business logic

---

### Layer 2: API Adapter Layer (@ds/api)
**Responsibility**: Domain-specific error transformation

**MUST**:
- Call `toStandardApiError()` on all errors
- Add domain-specific context
- Return typed AppError
- Handle AbortController signals

**MUST NOT**:
- Show UI notifications
- Implement React-specific logic
- Handle loading states

---

### Layer 3: Business Logic Layer (@ds/shared)
**Responsibility**: Business rule validation and state management

**MUST**:
- Validate inputs before API calls
- Throw descriptive errors for business rule violations
- Maintain clean error propagation
- Support cross-platform usage

**MUST NOT**:
- Depend on React
- Access DOM or browser APIs
- Display notifications

---

### Layer 4: UI Layer (React Components)
**Responsibility**: Error handling and user feedback

**MUST**:
- Call `handleError()` for all errors
- Unlock loading states in catch blocks
- Provide feature context
- Implement ErrorBoundary for component trees

**MUST NOT**:
- Use alert() or blocking dialogs
- Implement custom error display logic
- Skip error handling

---

## Error Code Standards

### EH-* Error Codes (Error Handling Enhancement)

**PURPOSE**: HTTP-layer technical errors mapped to user-friendly codes.

**SCOPE**: Network failures, authentication, server errors, timeouts.

**MAPPING**: Automatic via `toStandardApiError()` - DO NOT map manually.

**EXAMPLES**: EH-NET, EH-NET-TIMEOUT, EH-AUTH, EH-404, EH-SRV, EH-HTTP, EH-UNK, EH-RUN

---

### AUTH_* Error Codes

**PURPOSE**: Authentication and authorization business errors.

**SCOPE**: Login failures, token issues, permission errors.

**SOURCE**: Backend API responses.

**HANDLING**: Special treatment (e.g., redirect to login, show "Go to Login" button).

---

### VALIDATION_* Error Codes

**PURPOSE**: Form field and input validation errors.

**SCOPE**: Required fields, format errors, range violations.

**HANDLING**: Display inline at field level, NOT via handleError().

---

## AbortController Requirements

### When to Use

**MANDATORY** for:
- User-initiated cancellation (e.g., cancel button)
- Navigation away from pending request
- Timeout enforcement
- Cleanup in useEffect

**PATTERN**:
- Create AbortController before request
- Pass signal to API call
- Abort on cleanup/timeout
- Check if error is abort before handling

---

### How to Handle Abort

**DO NOT** call `handleError()` for aborted requests.

**REASON**: Aborted requests are intentional, not errors.

**DETECTION**: Check `error.name === 'AbortError'` or `error.code === 'ERR_CANCELED'`.

---

## ErrorBoundary Requirements

### Placement

**MANDATORY**: Wrap entire application and critical feature sections.

**MINIMUM**: One ErrorBoundary at app root.

**RECOMMENDED**: Additional boundaries around:
- Complex features
- Third-party components
- Experimental sections

---

### Error Display

**FORBIDDEN**: White screen of death.

**REQUIRED**: User-friendly fallback UI with:
- Clear error message
- Recovery actions (refresh, go home)
- Error reporting option

---

## Anti-Patterns

### 1. Silent Failures
**NEVER** swallow errors without handling.

### 2. Inconsistent Error Formats
**NEVER** create custom error objects. Always use AppError.

### 3. Mixed Concerns
**NEVER** put validation logic in API handlers or UI logic in business layer.

### 4. Resource Leaks
**NEVER** forget to abort pending requests on unmount.

### 5. Generic Error Messages
**NEVER** show raw error messages to users. Always map to user-friendly messages.

### 6. Blocking the Main Thread
**NEVER** use synchronous dialogs or long-running operations without async.

---

## Severity Levels

### low
- **Trigger**: Field validation errors
- **Display**: 3-second Toast (info level)
- **Action**: Show inline error

### medium
- **Trigger**: Business rule violations
- **Display**: 5-second Toast (warn level)
- **Action**: Allow retry or dismiss

### high
- **Trigger**: Authentication failures, critical errors
- **Display**: 8-second Toast (error level)
- **Action**: Redirect or require user action

### critical
- **Trigger**: System crashes, unrecoverable errors
- **Display**: Modal Dialog requiring user acknowledgment
- **Action**: Provide recovery path or escalate

---

## Notification Service Rules

### Toast Usage
**FOR**: Transient, non-critical information.

**DURATION**: Based on severity (3s/5s/8s).

**MAX VISIBLE**: 3 toasts simultaneously.

---

### Dialog Usage
**FOR**: Critical errors requiring user acknowledgment.

**BLOCKING**: Yes - user must dismiss.

**ACTIONS**: Provide clear recovery options (Retry, Go Home, Refresh).

---

## Testing Requirements

### Unit Tests
**MUST TEST**:
- Error code mapping correctness
- HTTP status to EH-* code conversion
- Context preservation through layers
- Loading state unlock in error scenarios

---

### Integration Tests
**MUST TEST**:
- End-to-end error flow (network → UI)
- AbortController cancellation
- ErrorBoundary catch and display
- Notification service dispatch

---

### E2E Tests
**MUST TEST**:
- User-visible error messages
- Recovery action functionality
- No frozen states after errors
- Proper error logging

---

## Migration Checklist

When migrating existing code to EHI:

- [ ] Replace all `alert()` with `handleError()`
- [ ] Add `try-catch` to all async operations
- [ ] Unlock loading states in catch blocks
- [ ] Provide context to `handleError()`
- [ ] Implement AbortController for cancellable requests
- [ ] Remove custom error display logic
- [ ] Add ErrorBoundary to component tree
- [ ] Convert validation errors to inline display
- [ ] Update tests to verify error handling
- [ ] Remove `console.log()` in production error paths

---

## Compliance Verification

Before merging any code:

1. **No alert()**: Search codebase for `alert(`, `confirm(`, `prompt(`
2. **All errors handled**: No naked try-catch without `handleError()`
3. **Loading states unlocked**: Every `setLoading(true)` has error-path unlock
4. **Context provided**: All `handleError()` calls include context object
5. **AbortController implemented**: Cancellable operations support abort
6. **ErrorBoundary present**: No component trees without boundary
7. **Tests pass**: All error handling tests green
8. **No hardcoded messages**: All user messages from error config

---

**Enforcement**: These are not suggestions. These are absolute requirements for all frontend code in the MonoFrontend architecture.

**Consequences of Violation**: Frozen UIs, poor user experience, difficult debugging, and technical debt.

**Authority**: This document supersedes any conflicting patterns in legacy code. When in doubt, follow these rules.
