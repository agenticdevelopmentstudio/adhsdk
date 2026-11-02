from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_ecosystem_move_response_200_moved import PostEcosystemMoveResponse200Moved


T = TypeVar("T", bound="PostEcosystemMoveResponse200")


@_attrs_define
class PostEcosystemMoveResponse200:
    """
    Attributes:
        schema (str | Unset):
        table (str | Unset):
        id (str | Unset):
        from_ (str | Unset):
        to (str | Unset):
        dry_run (bool | Unset):
        moved (PostEcosystemMoveResponse200Moved | Unset):
    """

    schema: str | Unset = UNSET
    table: str | Unset = UNSET
    id: str | Unset = UNSET
    from_: str | Unset = UNSET
    to: str | Unset = UNSET
    dry_run: bool | Unset = UNSET
    moved: PostEcosystemMoveResponse200Moved | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        schema = self.schema

        table = self.table

        id = self.id

        from_ = self.from_

        to = self.to

        dry_run = self.dry_run

        moved: dict[str, Any] | Unset = UNSET
        if not isinstance(self.moved, Unset):
            moved = self.moved.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if schema is not UNSET:
            field_dict["schema"] = schema
        if table is not UNSET:
            field_dict["table"] = table
        if id is not UNSET:
            field_dict["id"] = id
        if from_ is not UNSET:
            field_dict["from"] = from_
        if to is not UNSET:
            field_dict["to"] = to
        if dry_run is not UNSET:
            field_dict["dryRun"] = dry_run
        if moved is not UNSET:
            field_dict["moved"] = moved

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_ecosystem_move_response_200_moved import (
            PostEcosystemMoveResponse200Moved,
        )

        d = dict(src_dict)
        schema = d.pop("schema", UNSET)

        table = d.pop("table", UNSET)

        id = d.pop("id", UNSET)

        from_ = d.pop("from", UNSET)

        to = d.pop("to", UNSET)

        dry_run = d.pop("dryRun", UNSET)

        _moved = d.pop("moved", UNSET)
        moved: PostEcosystemMoveResponse200Moved | Unset
        if isinstance(_moved, Unset):
            moved = UNSET
        else:
            moved = PostEcosystemMoveResponse200Moved.from_dict(_moved)

        post_ecosystem_move_response_200 = cls(
            schema=schema,
            table=table,
            id=id,
            from_=from_,
            to=to,
            dry_run=dry_run,
            moved=moved,
        )

        post_ecosystem_move_response_200.additional_properties = d
        return post_ecosystem_move_response_200

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
