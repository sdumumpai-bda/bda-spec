---
tags: [type/design-system, ds/index]
version: 1.0.0
date: 2026-05-15
status: active
---

# Design System — Library Book Tracker

Version: 1.0.0 — active

## Files

- [[DS-Tokens]] — colors, typography, spacing, radius, shadow, motion
- [[DS-Components]] — UI components (Button, Input, Card, ...)
- [[DS-Patterns]] — common UI patterns
- [[DS-Accessibility]] — WCAG AA rules
- [[DS-Layout]] — grid, breakpoints
- [[DS-Voice]] — tone + microcopy

## Style

- Minimalist + Thai-first
- Light theme default; dark mode Phase 2
- Target: librarians (50+ comfortable), members (general public)

## Frameworks

- Web: React + Tailwind CSS (binds to DS tokens via custom config)
- (Phase 2) Mobile native: tokens exported as Flutter ThemeData / Swift / Kotlin

## Force-use rule

หลัง DS active — [[../../.claude/agents/frontend|frontend]] และ [[../../.claude/agents/mobile|mobile]] subagents ถูกบังคับใช้ tokens + components ที่นี่. ห้าม inline styling, ห้าม recreate component
