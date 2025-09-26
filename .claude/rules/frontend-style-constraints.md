# Frontend Style Development Constraints

**CRITICAL**: This document contains ABSOLUTE REQUIREMENTS for all frontend style development. Violations WILL result in CI failure and code rejection.

## MANDATORY PRE-DEVELOPMENT READING

**BEFORE ANY STYLE DEVELOPMENT**, you MUST read:
- `/monofrontend/docs/GETTING-STARTED-DSv2.md` - Complete system understanding

**FAILURE TO READ THIS DOCUMENT BEFORE DEVELOPMENT IS PROHIBITED.**

---

## ABSOLUTE PROHIBITIONS

### NEVER Use Hardcoded Styles

**FORBIDDEN VALUES:**
- ❌ Hex colors: `#3B82F6`, `#ffffff`, `#123`
- ❌ RGB functions: `rgb(59, 130, 246)`, `rgba(255, 255, 255, 0.5)`
- ❌ HSL functions: `hsl(217, 91%, 60%)`, `hsla(0, 100%, 50%, 0.8)`
- ❌ Hardcoded shadows: `box-shadow: 0 4px 6px rgba(0,0,0,0.1)`
- ❌ Hardcoded gradients: `linear-gradient(90deg, #3B82F6 0%, #1D4ED8 100%)`
- ❌ Hardcoded Tailwind colors: `bg-blue-500`, `text-red-600`, `border-gray-200`

### NEVER Bypass the Design Token System

**PROHIBITED BEHAVIORS:**
- ❌ Creating CSS files with hardcoded values
- ❌ Using inline styles with literal colors
- ❌ Adding custom CSS variables outside the token system
- ❌ Using `!important` to override token-based styles

**VIOLATION CONSEQUENCES:**
- Immediate CI failure
- Code rejection
- Mandatory rewrite using Design Token System

---

## MANDATORY WORKFLOW

### Token-First Development Process

**STEP 1: Identify Style Requirements**
- Determine what colors, spacing, shadows, or gradients you need

**STEP 2: Check Token Existence**
- Check: `packages/tokens/src/presets/light.ts`
- Check: `packages/tokens/src/presets/dark.ts`

**STEP 3: Token Decision**
```yaml
If token exists:
  → Use existing token: var(--color-brand-600)
  → Use semantic class: bg-bg-surface, text-fg-primary

If token missing:
  → ADD to light.ts: '--color-new-name': '#hexvalue'
  → ADD to dark.ts: '--color-new-name': '#darkversion'
  → THEN use: var(--color-new-name)
```

**STEP 4: Implement Styles**
```tsx
// REQUIRED: Use CSS variables
className="bg-[var(--color-bg-surface)] text-[var(--color-fg-primary)]"

// REQUIRED: Use semantic classes
className="bg-bg-surface text-fg-primary"

// REQUIRED: Gradient syntax
className="bg-[image:var(--gradient-primary)]"
```

**STEP 5: Validate (After Development)**
```bash
# MANDATORY after completing styles
pnpm ai:find-hardcode
```

### New Style Addition Process

**WHEN YOU NEED A NEW COLOR/SHADOW/GRADIENT:**

**STEP 1: Add to Light Theme**
```typescript
// Edit: packages/tokens/src/presets/light.ts
export const lightVars = {
  // ... existing tokens
  '--color-your-new-name': '#HEX_VALUE',
  '--shadow-your-new-name': '0 4px 6px rgba(0,0,0,0.1)',
  '--gradient-your-new-name': 'linear-gradient(90deg, #START 0%, #END 100%)'
};
```

**STEP 2: Add to Dark Theme**
```typescript
// Edit: packages/tokens/src/presets/dark.ts
export const darkVars = {
  // ... existing tokens
  '--color-your-new-name': '#DARK_HEX_VALUE',
  '--shadow-your-new-name': '0 4px 6px rgba(255,255,255,0.1)',
  '--gradient-your-new-name': 'linear-gradient(90deg, #DARK_START 0%, #DARK_END 100%)'
};
```

**STEP 3: Use in Components**
```tsx
// Use your new token
className="bg-[var(--color-your-new-name)]"
className="shadow-[var(--shadow-your-new-name)]"
className="bg-[image:var(--gradient-your-new-name)]"
```

**STEP 4: Verify**
```bash
pnpm ai:find-hardcode  # Should show zero violations
```

---

## TOOL ENFORCEMENT

### MANDATORY Validation Commands

**REQUIRED AFTER ANY STYLE CHANGES:**
```bash
# Check for hardcoded styles (MANDATORY)
pnpm ai:find-hardcode

# Fix any violations found (if needed)
pnpm ai:insert-variable "#hexcolor"

# Generate component scaffolding (for new components)
pnpm ai:scaffold component ComponentName
```

### MANDATORY Pre-Commit Checklist

**BEFORE EVERY COMMIT:**
- [ ] ✅ `pnpm ai:find-hardcode` shows zero violations
- [ ] ✅ All colors use `var(--color-*)` or semantic classes
- [ ] ✅ All gradients use `bg-[image:var(--gradient-*)]`
- [ ] ✅ All shadows use `shadow-*` classes or `var(--shadow-*)`

**COMMIT WILL BE REJECTED if any item fails.**

---

## EMERGENCY PROCEDURES

### CRITICAL: System Malfunction Response

**IF DESIGN TOKEN SYSTEM FAILS:**
1. 🚨 **IMMEDIATELY STOP** all styling development
2. 🔧 **CHECK** TokensProvider configuration in app entry
3. 📞 **NOTIFY** team lead of system failure
4. 🚫 **NEVER** revert to hardcoded styles
5. ⏳ **WAIT** for system restoration

**TEMPORARY HARDCODED STYLING IS NEVER PERMITTED UNDER ANY CIRCUMSTANCES.**

---

## VIOLATION CONSEQUENCES

### Immediate Actions for Violations

**HARDCODED STYLE DETECTED:**
1. 🚫 **STOP DEVELOPMENT**
2. 🛠️ **FIX** using token system
3. ✅ **VERIFY** with `pnpm ai:find-hardcode`

**CI FAILURE:**
1. 🚫 **COMMIT REJECTED**
2. 🔄 **MANDATORY REWRITE** required
3. 📚 **RE-READ** constraints document

### Escalation Process

**REPEATED VIOLATIONS:**
- First: Warning + re-training
- Second: Code review required for all styling
- Third: Temporary frontend development suspension

---

## QUICK REFERENCE

### Essential Commands
```bash
pnpm ai:find-hardcode        # Check for violations
pnpm ai:insert-variable      # Fix hardcoded colors
pnpm ai:scaffold component   # Generate component template
```

### Essential Files
```
packages/tokens/src/presets/light.ts   # Light theme tokens
packages/tokens/src/presets/dark.ts    # Dark theme tokens
```

### Essential Syntax
```tsx
// CSS Variables
var(--color-brand-600)
var(--shadow-md)
var(--gradient-primary)

// Semantic Classes
bg-bg-surface text-fg-primary border-border-default

// Gradient Syntax
bg-[image:var(--gradient-primary)]
```

---

## FINAL WARNING

🔥 **ZERO TOLERANCE**: Any hardcoded styling will result in immediate code rejection.

🛡️ **SYSTEM INTEGRITY**: Design Token System is the ONLY authorized styling method.

⚡ **ENFORCEMENT**: Automated CI + manual review catch all violations.

**Your compliance ensures system consistency. Non-compliance threatens the entire architecture.**

---

**Document Version**: 2.0
**Last Updated**: 2025-09-22
**Authority**: Design Token System v2
**Enforcement**: Automatic CI + Manual Review