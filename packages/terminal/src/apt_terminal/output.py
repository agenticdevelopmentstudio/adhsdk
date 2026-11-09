from __future__ import annotations

import json
import sys
from collections.abc import Iterable, Sequence
from datetime import UTC, datetime
from typing import Any

from rich.console import Console
from rich.table import Table

_console = Console()
_err_console = Console(stderr=True)


def emit_json(data: Any) -> None:
    json.dump(data, sys.stdout, indent=2, default=str)
    sys.stdout.write("\n")


def emit_table(
    rows: Sequence[dict[str, Any]],
    columns: Sequence[str] | None = None,
    *,
    title: str | None = None,
) -> None:
    if not rows:
        _console.print("[dim](none)[/dim]")
        return
    if columns is None:
        seen: list[str] = []
        for row in rows:
            for key in row:
                if key not in seen:
                    seen.append(key)
        columns = seen
    t = Table(title=title, show_lines=False, header_style="bold")
    for col in columns:
        t.add_column(col)
    for row in rows:
        t.add_row(*[_fmt_cell(c, row.get(c)) for c in columns])
    _console.print(t)


def emit_kv(pairs: Iterable[tuple[str, Any]]) -> None:
    t = Table(show_header=False, box=None, padding=(0, 1))
    t.add_column("k", style="bold")
    t.add_column("v")
    for k, v in pairs:
        t.add_row(k, _fmt(v))
    _console.print(t)


def render(data: Any, json_out: bool) -> None:
    """Authoritative renderer: dispatch data to the appropriate emitter."""
    if data is None:
        return
    if json_out:
        emit_json(data)
        return
    if isinstance(data, list):
        if all(isinstance(item, dict) for item in data):
            emit_table(data)
        else:
            for item in data:
                emit_text(item if isinstance(item, str) else json.dumps(item, default=str))
        return
    if isinstance(data, dict):
        emit_table([data])
        return
    emit_text(str(data))


def emit_text(s: str) -> None:
    sys.stdout.write(s if s.endswith("\n") else s + "\n")


def confirm(prompt: str, *, assume_yes: bool = False) -> bool:
    if assume_yes:
        return True
    _err_console.print(f"{prompt} [y/N] ", end="")
    try:
        ans = input().strip().lower()
    except EOFError:
        return False
    return ans in {"y", "yes"}


def warn(msg: str) -> None:
    _err_console.print(f"[yellow]warn[/yellow] {msg}")


def die(msg: str, code: int = 1) -> None:
    _err_console.print(f"[red]error[/red] {msg}")
    raise SystemExit(code)


# /v1 sends a resource's creation and update times as unix seconds under these keys; every
# other timestamp stays an ISO string. `--json` keeps the wire value, a table reads it as UTC.
UNIX_TIME_KEYS = frozenset({"created", "updated"})


def _fmt_cell(column: str, v: Any) -> str:
    if column in UNIX_TIME_KEYS and isinstance(v, int) and not isinstance(v, bool):
        return datetime.fromtimestamp(v, tz=UTC).strftime("%Y-%m-%d %H:%M:%SZ")
    return _fmt(v)


def _fmt(v: Any) -> str:
    if v is None:
        return "[dim]—[/dim]"
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (dict, list)):
        return json.dumps(v, default=str)
    return str(v)
