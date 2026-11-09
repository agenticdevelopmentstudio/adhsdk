from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ContentRelationshipsBody")


@_attrs_define
class PostV1ContentRelationshipsBody:
    """
    Attributes:
        contact_id (str):
        ecosystem_id (str | Unset):
        owner_kind (str | Unset):
        owner_id (str | Unset):
        relationship_kind (str | Unset):
        since_date (str | Unset):
        notes (str | Unset):
    """

    contact_id: str
    ecosystem_id: str | Unset = UNSET
    owner_kind: str | Unset = UNSET
    owner_id: str | Unset = UNSET
    relationship_kind: str | Unset = UNSET
    since_date: str | Unset = UNSET
    notes: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        contact_id = self.contact_id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        relationship_kind = self.relationship_kind

        since_date = self.since_date

        notes = self.notes

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "contact_id": contact_id,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if owner_kind is not UNSET:
            field_dict["owner_kind"] = owner_kind
        if owner_id is not UNSET:
            field_dict["owner_id"] = owner_id
        if relationship_kind is not UNSET:
            field_dict["relationship_kind"] = relationship_kind
        if since_date is not UNSET:
            field_dict["since_date"] = since_date
        if notes is not UNSET:
            field_dict["notes"] = notes

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        contact_id = d.pop("contact_id")

        ecosystem_id = d.pop("ecosystem_id", UNSET)

        owner_kind = d.pop("owner_kind", UNSET)

        owner_id = d.pop("owner_id", UNSET)

        relationship_kind = d.pop("relationship_kind", UNSET)

        since_date = d.pop("since_date", UNSET)

        notes = d.pop("notes", UNSET)

        post_v1_content_relationships_body = cls(
            contact_id=contact_id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            relationship_kind=relationship_kind,
            since_date=since_date,
            notes=notes,
        )

        return post_v1_content_relationships_body
