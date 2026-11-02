from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutContentQueuesIdBody")


@_attrs_define
class PutContentQueuesIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        name (str | Unset):
        sync_txid (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    name: str | Unset = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        name = self.name

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if name is not UNSET:
            field_dict["name"] = name
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        name = d.pop("name", UNSET)

        sync_txid = d.pop("syncTxid", UNSET)

        put_content_queues_id_body = cls(
            ecosystem_id=ecosystem_id,
            name=name,
            sync_txid=sync_txid,
        )

        return put_content_queues_id_body
