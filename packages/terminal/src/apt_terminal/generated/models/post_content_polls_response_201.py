from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PostContentPollsResponse201")


@_attrs_define
class PostContentPollsResponse201:
    """
    Attributes:
        id (str):
        customer_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        host_kind (None | str):
        host_id (None | str):
        question (str):
        allow_multiple (bool):
        expires_at (None | str):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    customer_id: str
    deleted_at: None | str
    ecosystem_id: str
    host_kind: None | str
    host_id: None | str
    question: str
    allow_multiple: bool
    expires_at: None | str
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        customer_id = self.customer_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        host_kind: None | str
        host_kind = self.host_kind

        host_id: None | str
        host_id = self.host_id

        question = self.question

        allow_multiple = self.allow_multiple

        expires_at: None | str
        expires_at = self.expires_at

        created_at = self.created_at

        updated_at = self.updated_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "customerId": customer_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "hostKind": host_kind,
                "hostId": host_id,
                "question": question,
                "allowMultiple": allow_multiple,
                "expiresAt": expires_at,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
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

        def _parse_host_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        host_kind = _parse_host_kind(d.pop("hostKind"))

        def _parse_host_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        host_id = _parse_host_id(d.pop("hostId"))

        question = d.pop("question")

        allow_multiple = d.pop("allowMultiple")

        def _parse_expires_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        expires_at = _parse_expires_at(d.pop("expiresAt"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        post_content_polls_response_201 = cls(
            id=id,
            customer_id=customer_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            host_kind=host_kind,
            host_id=host_id,
            question=question,
            allow_multiple=allow_multiple,
            expires_at=expires_at,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return post_content_polls_response_201
