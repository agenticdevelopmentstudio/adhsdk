from __future__ import annotations

from apt_terminal import resources as r


def test_persona_has_expected_resources():
    names = {res.name for res in r.PERSONA}
    assert names == {"services", "personas", "models", "templates"}


def test_services_ops_resolve_to_real_modules():
    services = next(res for res in r.PERSONA if res.name == "services")
    assert hasattr(services.ops.list_, "sync_detailed")
    assert hasattr(services.ops.create, "sync_detailed")
    assert services.create_body is not None
    # named actions exist
    action_names = {a.name for a in services.actions}
    assert {"connect", "models", "models-refresh"} <= action_names


def test_every_op_is_a_v1_route():
    resources = (*r.PERSONA, *r.AUTH_TOKENS)
    for res in resources:
        mods = [m for m in (res.ops.list_, res.ops.get, res.ops.create, res.ops.update,
                            res.ops.delete) if m is not None]
        mods += [a.op for a in res.actions]
        for mod in mods:
            assert mod.__name__.rsplit(".", 1)[-1].split("_", 2)[1] == "v1", mod.__name__


def test_all_domains_indexes_persona():
    assert "persona" in r.ALL_DOMAINS
    assert r.ALL_DOMAINS["persona"] is r.PERSONA
