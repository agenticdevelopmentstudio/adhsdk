from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostEcosystemMoveBody")


@_attrs_define
class PostEcosystemMoveBody:
    """
    Attributes:
        schema (str): Postgres schema of the row’s table
        table (str): table name within the schema
        id (str): row id (uuid, or an rdid for rdid-addressed tables)
        target (str): destination ecosystem (uuid or rdid)
        dry_run (bool | Unset): report what would move without writing
    """

    schema: str
    table: str
    id: str
    target: str
    dry_run: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        schema = self.schema

        table = self.table

        id = self.id

        target = self.target

        dry_run = self.dry_run

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "schema": schema,
                "table": table,
                "id": id,
                "target": target,
            }
        )
        if dry_run is not UNSET:
            field_dict["dryRun"] = dry_run

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        schema = d.pop("schema")

        table = d.pop("table")

        id = d.pop("id")

        target = d.pop("target")

        dry_run = d.pop("dryRun", UNSET)

        post_ecosystem_move_body = cls(
            schema=schema,
            table=table,
            id=id,
            target=target,
            dry_run=dry_run,
        )

        post_ecosystem_move_body.additional_properties = d
        return post_ecosystem_move_body

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
