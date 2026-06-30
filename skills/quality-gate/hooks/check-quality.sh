#!/bin/bash
# Runs quality checks on the project's source and prints violations.
# Exit 0 = pass, exit 1 = violations found (details on stdout).
#
# Language-agnostic thresholds (file <=150 lines, function <=30, params <=4,
# complexity <=10, magic numbers, duplicate strings <=3, class attrs/coupling <=6)
# are enforced per-language by the linter configs in ../config, plus the universal
# file-length and (Python) class-attribute checks below.
#
# Adjust the source directories / linters below to match your project layout.

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0

VIOLATIONS=""

# --- Python: flake8 (+ plugins, configured by config/python.flake8) -----------
if command -v flake8 >/dev/null 2>&1; then
  for SRC in python/src src; do
    if [ -d "$SRC" ]; then
      FLAKE=$(flake8 "$SRC" 2>&1)
      [ -n "$FLAKE" ] && VIOLATIONS+="$FLAKE"$'\n'
      break
    fi
  done
fi

# --- Java: checkstyle (configured by config/java-checkstyle.xml) ---------------
if command -v checkstyle >/dev/null 2>&1 && [ -d java ]; then
  CS=$(checkstyle -c java/checkstyle.xml $(find java -name '*.java') 2>&1 | grep -E '^\[(WARN|ERROR)\]')
  [ -n "$CS" ] && VIOLATIONS+="$CS"$'\n'
fi

# --- Universal: file length (max 150 lines) -----------------------------------
while IFS= read -r f; do
  LINES=$(wc -l < "$f")
  if [ "$LINES" -gt 150 ]; then
    VIOLATIONS+="$f:1:1: FILE-LENGTH File has $LINES lines (max 150)"$'\n'
  fi
done < <(find . -type f \( -name '*.py' -o -name '*.java' -o -name '*.ts' -o -name '*.go' \) \
           ! -name '__init__.py' ! -path '*/node_modules/*' ! -path '*/.venv/*' ! -path '*/vendor/*')

# --- Python: class instance attribute count (max 6, incl. private) ------------
# WPS230 only counts public attrs; this catches all self.* assignments in __init__.
if command -v python3 >/dev/null 2>&1 && [ -d src ] || [ -d python/src ]; then
  ATTR_CHECK=$(python3 -c "
import ast, os
max_attrs = 6
roots = [d for d in ('src', 'python/src') if os.path.isdir(d)]
for base in roots:
    for root, _dirs, files in os.walk(base):
        for fname in files:
            if not fname.endswith('.py') or fname == '__init__.py':
                continue
            path = os.path.join(root, fname)
            with open(path) as f:
                try:
                    tree = ast.parse(f.read())
                except SyntaxError:
                    continue
            for node in ast.walk(tree):
                if not isinstance(node, ast.ClassDef):
                    continue
                init_attrs = set()
                for child in ast.walk(node):
                    if isinstance(child, ast.FunctionDef) and child.name == '__init__':
                        for n in ast.walk(child):
                            if (isinstance(n, ast.Attribute)
                                and isinstance(n.ctx, ast.Store)
                                and isinstance(n.value, ast.Name)
                                and n.value.id == 'self'):
                                init_attrs.add(n.attr)
                if len(init_attrs) > max_attrs:
                    print(f'{path}:{node.lineno}:1: CLASS-ATTRS Class {node.name} has {len(init_attrs)} instance attributes (max {max_attrs}): {sorted(init_attrs)}')
" 2>&1)
  [ -n "$ATTR_CHECK" ] && VIOLATIONS+="$ATTR_CHECK"$'\n'
fi

if [ -n "$VIOLATIONS" ]; then
  echo "$VIOLATIONS"
  exit 1
fi

exit 0
