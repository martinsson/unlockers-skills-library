---
name: move-files
description: Move, relocate, or reorganize source files/modules between directories while updating all imports cleanly — without leaving behind re-export shim files. Use when restructuring a codebase's file layout.
argument-hint: "[source] [destination]"
---

# Move Files

When moving source files or modules to a new location, follow these principles. The
examples use Python `import` syntax, but the rule applies to any language with a module/
import system (TypeScript `import`, Java `package`/`import`, Go packages, C# `using`, …).

## Core Principle: No Re-export Shims

**Never leave behind "shim" files** that simply import from the new location and re-export.
Instead, update all consumers to import directly from the new location.

Bad (re-export shim left behind):
```python
# old_location/module.py — DON'T do this
from new_location.module import MyClass
__all__ = ["MyClass"]
```

Good (update imports at the source):
```python
# consumer.py — DO this
from new_location.module import MyClass  # updated to new location
```

## Process

### 1. Identify All Consumers
Before moving anything, find every file that imports from the module(s) being moved:
- Search for both `from old.path import` and `import old.path` style references (and the
  equivalent in your language).
- Check package index / barrel files (`__init__.py`, `index.ts`, …) that re-export symbols.
- Check test files — they often have their own imports.
- Look for string references (configuration, dependency injection, dynamic imports).

### 2. Move the File(s)
Move the file(s) to the new location.

### 3. Update All Imports
For every consumer found in step 1:
- Change the import path to point directly to the new location.
- Do not create intermediate re-export files.
- If a barrel/index file was re-exporting the moved symbol, either remove the re-export
  line (if nothing imports through it) or update consumers to the new path and then remove it.

### 4. Clean Up Empty Packages
- If a package index file is now empty (or only has unused re-exports), delete it.
- If a directory becomes empty after cleanup, delete the directory.
- Remove any build/cache artifacts left behind (e.g. `__pycache__`).

### 5. Verify
- Search for any remaining references to the old import path.
- Confirm no file still imports from the old location.
- Run tests if available to catch any missed references.
