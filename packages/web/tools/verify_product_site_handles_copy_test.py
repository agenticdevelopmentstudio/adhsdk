#!/usr/bin/env python3
"""Regression tests for verify_product_site_handles_copy.py: sync, drift both ways, blindness.
Plain asserts, no framework.
Run: python3 packages/web/tools/verify_product_site_handles_copy_test.py   (exit 0 = pass).

Each scenario builds a throwaway repo tree, copies the guard INTO it and imports it from there,
so `REPO = parents[3]` is exercised for real. The backend's rdid.ts is a fixture written here:
the real one is in another repo, and this test must run without it.
"""
import contextlib
import importlib.util
import io
import os
import shutil
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
GUARD = HERE / "verify_product_site_handles_copy.py"
REAL = HERE.parents[2]  # <repo>/packages/web/tools -> <repo>
REAL_COPY = REAL / "packages/web/packages/adh/src/site/reservedSlugs.ts"

cases: list[tuple[str, object, object]] = []


def check(name, got, want):
    cases.append((name, got, want))


def backend_rdid(extra: str = "", drop: str = "") -> str:
    """A minimal rdid.ts holding the real copy's words, as the backend spells its array."""
    spec = importlib.util.spec_from_file_location("guard_real", GUARD)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    words = sorted(w for w in module.handle_words(REAL_COPY) if w != drop)
    if extra:
        words.append(extra)
    body = "".join(f"  '{w}',\n" for w in words)
    return f"export const PRODUCT_SITE_HANDLE_WORDS: readonly string[] = [\n{body}];\n"


def scenario(rdid_text: str | None, *argv: str) -> tuple[int, str]:
    with tempfile.TemporaryDirectory() as raw:
        tmp = Path(raw) / "adhsdk"
        site = tmp / "packages/web/packages/adh/src/site"
        tools = tmp / "packages/web/tools"
        site.mkdir(parents=True)
        tools.mkdir(parents=True)
        shutil.copy(GUARD, tools / GUARD.name)
        shutil.copy(REAL_COPY, site / "reservedSlugs.ts")
        args = list(argv)
        if rdid_text is not None:
            rdid = Path(raw) / "rdid.ts"
            rdid.write_text(rdid_text)
            args = ["--rdid", str(rdid), *args]
        spec = importlib.util.spec_from_file_location(f"guard_{Path(raw).name}", tools / GUARD.name)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        saved = os.environ.pop("ADH_BACKEND_RDID", None)
        buf = io.StringIO()
        try:
            with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
                code = module.main(args)
        finally:
            if saved is not None:
                os.environ["ADH_BACKEND_RDID"] = saved
        return code, buf.getvalue()


code, out = scenario(backend_rdid())
check("in-sync lists pass", code, 0)
check("in-sync reports the count", "13 word(s) match" in out, True)

code, out = scenario(backend_rdid(extra="docs"))
check("a word only the backend holds is drift", code, 1)
check("drift names the backend's word", "only in the backend" in out and "docs" in out, True)

code, out = scenario(backend_rdid(drop="www"))
check("a word only the copy holds is drift", code, 1)
check("drift names the copy's word", "only in the copy" in out and "www" in out, True)

code, out = scenario("export const SOMETHING_ELSE = []\n")
check("an unparseable backend exits 2", code, 2)
check("an unparseable backend says it failed to check", "FAILED TO CHECK" in out, True)

code, out = scenario(None)
check("no backend exits 2", code, 2)
check("no backend says it failed to check", "FAILED TO CHECK" in out, True)

code, out = scenario(None, "--if-backend")
check("no backend under --if-backend is a skip", code, 0)
check("the skip is printed", "SKIPPED" in out, True)


failed = [(n, g, w) for n, g, w in cases if g != w]
for name, got, want in failed:
    print(f"FAIL  {name}: got {got!r}, want {want!r}", file=sys.stderr)
print(f"verify_product_site_handles_copy_test: {len(cases) - len(failed)}/{len(cases)} passed")
sys.exit(1 if failed else 0)
