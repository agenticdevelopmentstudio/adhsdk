from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostContentRelationshipsBody")


@_attrs_define
class PostContentRelationshipsBody:
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
                "contactId": contact_id,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if owner_kind is not UNSET:
            field_dict["ownerKind"] = owner_kind
        if owner_id is not UNSET:
            field_dict["ownerId"] = owner_id
        if relationship_kind is not UNSET:
            field_dict["relationshipKind"] = relationship_kind
        if since_date is not UNSET:
            field_dict["sinceDate"] = since_date
        if notes is not UNSET:
            field_dict["notes"] = notes

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        contact_id = d.pop("contactId")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        owner_kind = d.pop("ownerKind", UNSET)

        owner_id = d.pop("ownerId", UNSET)

        relationship_kind = d.pop("relationshipKind", UNSET)

        since_date = d.pop("sinceDate", UNSET)

        notes = d.pop("notes", UNSET)

        post_content_relationships_body = cls(
            contact_id=contact_id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            relationship_kind=relationship_kind,
            since_date=since_date,
            notes=notes,
        )

        return post_content_relationships_body
