---
tags: [type/test-plan]
status: draft                  # draft | active | archived
date: <YYYY-MM-DD>
feature: [[FEAT-<slug>]]
target: <web | mobile | api | cross>
---

# Test Plan — <Title>

## 1. Scope
<what this plan covers + what it doesn't>

## 2. Roles to test
- <Role A>
- <Role B>

## 3. Scenarios

### TC-001 — <scenario title>
- **Pre-condition**: <state>
- **Steps**:
  1. <step 1>
  2. <step 2>
- **Expected**: <result>
- **Route source**: VISIBLE_MENU / DIRECT_URL_USER / DIRECT_URL_TECHNICAL
- **Auth**: <role required>

### TC-002 — ...

## 4. Evidence requirements
- Screenshots per step
- Console + network logs
- PII masking required if data contains: <list>

## 5. Done definition
- [ ] All scenarios PASS / acknowledged BLOCKED
- [ ] Evidence collected per BDA standard format
- [ ] No PII leaks
- [ ] Manifest signed: safe_to_share: true (per item)
