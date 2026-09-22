# 05-yagni.md — YAGNI (condensed)

> Category: QUALITY | Authority: core-constitution §2 / Global Harness Contract §Completion. ALWAYS LOADED — You Ain't Gonna Need It.

## Principles
- **No premature abstraction** — solve the problem at hand
- **No imagined futures** — don't build for "maybe later"
- **Standard library first** — prefer stdlib over new dependencies
- **Flat over nested** — prefer simple structures
- **If complex, it's wrong** — simplify until obvious

## Anti-Patterns to Avoid
- ❌ Abstract base classes for single implementations
- ❌ Plugin systems for single plugins
- ❌ Configuration for single values
- ❌ Interfaces for single implementations
- ❌ Event systems for single events
- ❌ Factory patterns for single types

## When to Generalize
Only when you have **3+ concrete instances** of the same pattern with identical behavior.
Then: extract, don't invent.