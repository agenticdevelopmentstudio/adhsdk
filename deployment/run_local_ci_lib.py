"""Pure helpers for `deployment/run-local-ci`, split out so they can be tested without pnpm."""


def steps_to_run(names: list[str], start: str | None, skip: list[str]) -> list[str]:
    """The step names to run, in order: from `start` (or the first) onward, minus `skip`.

    A skipped step is dropped, not reported as passed; the caller prints each skip so a
    green run never hides which step it did not run. An unknown name is an error here too,
    so a typo cannot silently skip nothing.
    """
    unknown = [n for n in [*skip, *([start] if start else [])] if n not in names]
    if unknown:
        raise ValueError(f"unknown step(s): {', '.join(unknown)}")
    first = names.index(start) if start else 0
    return [n for n in names[first:] if n not in skip]
