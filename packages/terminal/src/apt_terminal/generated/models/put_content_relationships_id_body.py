from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutContentRelationshipsIdBody")


@_attrs_define
class PutContentRelationshipsIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        owner_kind (str | Unset):
        owner_id (str | Unset):
        contact_id (str | Unset):
        relationship_kind (str | Unset):
        since_date (str | Unset):
        notes (str | Unset):
        sync_txid (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    owner_kind: str | Unset = UNSET
    owner_id: str | Unset = UNSET
    contact_id: str | Unset = UNSET
    relationship_kind: str | Unset = UNSET
    since_date: str | Unset = UNSET
    notes: str | Unset = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        contact_id = self.contact_id

        relationship_kind = self.relationship_kind

        since_date = self.since_date

        notes = self.notes

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if owner_kind is not UNSET:
            field_dict["ownerKind"] = owner_kind
        if owner_id is not UNSET:
            field_dict["ownerId"] = owner_id
        if contact_id is not UNSET:
            field_dict["contactId"] = contact_id
        if relationship_kind is not UNSET:
            field_dict["relationshipKind"] = relationship_kind
        if since_date is not UNSET:
            field_dict["sinceDate"] = since_date
        if notes is not UNSET:
            field_dict["notes"] = notes
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        owner_kind = d.pop("ownerKind", UNSET)

        owner_id = d.pop("ownerId", UNSET)

        contact_id = d.pop("contactId", UNSET)

        relationship_kind = d.pop("relationshipKind", UNSET)

        since_date = d.pop("sinceDate", UNSET)

        notes = d.pop("notes", UNSET)

        sync_txid = d.pop("syncTxid", UNSET)

        put_content_relationships_id_body = cls(
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            contact_id=contact_id,
            relationship_kind=relationship_kind,
            since_date=since_date,
            notes=notes,
            sync_txid=sync_txid,
        )

        return put_content_relationships_id_body
