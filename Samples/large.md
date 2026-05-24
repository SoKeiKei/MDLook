# Large File Placeholder

Use this sample as a starting point for large-file testing.

To create a file larger than the v1 preview limit:

```sh
python3 - <<'PY'
from pathlib import Path
Path("Samples/generated-large.md").write_text("# Big\n\n" + ("line\n" * 500000))
PY
```

Finder should show the “too large to preview safely” page instead of hanging.

