from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutContentTagsIdBody")


@_attrs_define
class PutContentTagsIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        owner_kind (str | Unset):
        owner_id (str | Unset):
        kind (str | Unset):
        label (str | Unset):
        level (str | Unset):
        since_date (str | Unset):
        notes (str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    owner_kind: str | Unset = UNSET
    owner_id: str | Unset = UNSET
    kind: str | Unset = UNSET
    label: str | Unset = UNSET
    level: str | Unset = UNSET
    since_date: str | Unset = UNSET
    notes: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        kind = self.kind

        label = self.label

        level = self.level

        since_date = self.since_date

        notes = self.notes

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if owner_kind is not UNSET:
            field_dict["ownerKind"] = owner_kind
        if owner_id is not UNSET:
            field_dict["ownerId"] = owner_id
        if kind is not UNSET:
            field_dict["kind"] = kind
        if label is not UNSET:
            field_dict["label"] = label
        if level is not UNSET:
            field_dict["level"] = level
        if since_date is not UNSET:
            field_dict["sinceDate"] = since_date
        if notes is not UNSET:
            field_dict["notes"] = notes

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        owner_kind = d.pop("ownerKind", UNSET)

        owner_id = d.pop("ownerId", UNSET)

        kind = d.pop("kind", UNSET)

        label = d.pop("label", UNSET)

        level = d.pop("level", UNSET)

        since_date = d.pop("sinceDate", UNSET)

        notes = d.pop("notes", UNSET)

        put_content_tags_id_body = cls(
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            kind=kind,
            label=label,
            level=level,
            since_date=since_date,
            notes=notes,
        )

        return put_content_tags_id_body
