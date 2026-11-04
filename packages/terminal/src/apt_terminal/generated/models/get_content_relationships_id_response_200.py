from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetContentRelationshipsIdResponse200")


@_attrs_define
class GetContentRelationshipsIdResponse200:
    """
    Attributes:
        id (str):
        customer_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        contact_id (str):
        relationship_kind (str):
        since_date (str):
        notes (str):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        author_kind (None | str):
        author_id (None | str):
    """

    id: str
    customer_id: str
    deleted_at: None | str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    contact_id: str
    relationship_kind: str
    since_date: str
    notes: str
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    author_kind: None | str
    author_id: None | str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        customer_id = self.customer_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        contact_id = self.contact_id

        relationship_kind = self.relationship_kind

        since_date = self.since_date

        notes = self.notes

        created_at = self.created_at

        updated_at = self.updated_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "customerId": customer_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "contactId": contact_id,
                "relationshipKind": relationship_kind,
                "sinceDate": since_date,
                "notes": notes,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
                "authorKind": author_kind,
                "authorId": author_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        customer_id = d.pop("customerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        ecosystem_id = d.pop("ecosystemId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        contact_id = d.pop("contactId")

        relationship_kind = d.pop("relationshipKind")

        since_date = d.pop("sinceDate")

        notes = d.pop("notes")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("authorKind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("authorId"))

        get_content_relationships_id_response_200 = cls(
            id=id,
            customer_id=customer_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            contact_id=contact_id,
            relationship_kind=relationship_kind,
            since_date=since_date,
            notes=notes,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            author_kind=author_kind,
            author_id=author_id,
        )

        return get_content_relationships_id_response_200
