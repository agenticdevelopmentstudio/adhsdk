"""Regression test for gen_table_metadata.body_properties: a /v1 update body that folds
sub-resource writes in as an `allOf` must still expose the row's own fields, or every
create field is emitted `createOnly` and the CRUD editor refuses to edit them (this is
what happened to ecosystem/applications and ecosystem/ecosystems).
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import gen_table_metadata as gen  # noqa: E402


def test_top_level_properties_and_required():
    props, required = gen.body_properties(
        {"type": "object", "properties": {"slug": {}, "name": {}}, "required": ["slug"]}
    )
    assert set(props) == {"slug", "name"}
    assert required == {"slug"}


def test_allof_members_are_merged():
    props, required = gen.body_properties(
        {
            "allOf": [
                {"properties": {"slug": {}, "display_name": {}}, "required": ["slug"]},
                {"properties": {"client_auth": {}, "schema_grants": {}}},
            ]
        }
    )
    assert set(props) == {"slug", "display_name", "client_auth", "schema_grants"}
    assert required == {"slug"}


def test_folded_sub_resource_is_not_an_edit_only_column():
    row = {"properties": {"id": {}, "slug": {}}}
    paths = {
        "/v1/things": {
            "x-exposure": "owner",
            "get": {
                "x-adh-replaces": ["GET /content/things"],
                "responses": {"200": {"content": {"application/json": {"schema": {
                    "properties": {"data": {"items": row}}}}}}},
            },
            "post": {
                "x-adh-replaces": ["POST /content/things"],
                "requestBody": {"content": {"application/json": {"schema": {
                    "properties": {"id": {}, "slug": {}}}}}},
            },
        },
        "/v1/things/{id}": {
            "get": {"x-adh-replaces": ["GET /content/things/{id}"]},
            "post": {
                "x-adh-replaces": ["PUT /content/things/{id}"],
                "requestBody": {"content": {"application/json": {"schema": {"allOf": [
                    {"properties": {"slug": {}}},
                    {"properties": {"settings": {}}},
                ]}}}},
            },
            "delete": {"x-adh-replaces": ["DELETE /content/things/{id}"]},
        },
    }
    (table,) = gen.find_tables(paths)
    by_name = {c["name"]: c for c in table["columns"]}
    assert by_name["id"].get("createOnly") is True
    assert "createOnly" not in by_name["slug"]
    assert "settings" not in by_name
