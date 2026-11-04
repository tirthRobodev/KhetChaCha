import os
import glob
from pathlib import Path

engine_dir = Path("ai_engine").resolve()
for py_file in engine_dir.rglob("*.py"):
    if ".venv" in py_file.parts or "__pycache__" in py_file.parts:
        continue
    try:
        with open(py_file, "r", encoding="utf-8") as f:
            for i, line in enumerate(f, 1):
                if any(k in line for k in ['"data"', "'data'", "data/", "data\\\\"]):
                    rel = py_file.relative_to(engine_dir)
                    print(f"{rel}:{i}: {line.strip()}")
    except Exception as e:
        pass
