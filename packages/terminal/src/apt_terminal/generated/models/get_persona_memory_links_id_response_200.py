from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetPersonaMemoryLinksIdResponse200")


@_attrs_define
class GetPersonaMemoryLinksIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        customer_id (str):
        src_id (str):
        dst_id (str):
        relation (str):
        created_at (str):
        updated_at (str):
        deleted_at (None | str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
    """

    id: str
    ecosystem_id: str
    customer_id: str
    src_id: str
    dst_id: str
    relation: str
    created_at: str
    updated_at: str
    deleted_at: None | str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        customer_id = self.customer_id

        src_id = self.src_id

        dst_id = self.dst_id

        relation = self.relation

        created_at = self.created_at

        updated_at = self.updated_at

        deleted_at: None | str
        deleted_at = self.deleted_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "customerId": customer_id,
                "srcId": src_id,
                "dstId": dst_id,
                "relation": relation,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "deletedAt": deleted_at,
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

        ecosystem_id = d.pop("ecosystemId")

        customer_id = d.pop("customerId")

        src_id = d.pop("srcId")

        dst_id = d.pop("dstId")

        relation = d.pop("relation")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        get_persona_memory_links_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            customer_id=customer_id,
            src_id=src_id,
            dst_id=dst_id,
            relation=relation,
            created_at=created_at,
            updated_at=updated_at,
            deleted_at=deleted_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_persona_memory_links_id_response_200
