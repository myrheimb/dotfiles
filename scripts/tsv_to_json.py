"""Convert tab-separated data (e.g. copied from Excel) into JSON.

Example usage: Copy the data you want to convert and run `pbpaste | tsv-to-json`.
"""

import csv
import io
import json
import sys


def tsv_to_json(tsv_text) -> list[dict[str, str]]:
    """Parse tab-separated text into a list of dicts, collapsing whitespace in values."""
    reader = csv.DictReader(io.StringIO(tsv_text), delimiter="\t")
    return [
        {key: " ".join(value.split()) for key, value in row.items()} for row in reader
    ]


if __name__ == "__main__":
    data = sys.stdin.read()
    print(json.dumps(tsv_to_json(data), indent=2, ensure_ascii=False))  # noqa: T201
