from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostContentCountersBody")


@_attrs_define
class PostContentCountersBody:
    """
    Attributes:
        name (str):
        value (int):
        ecosystem_id (str | Unset):
        sync_txid (int | Unset):
    """

    name: str
    value: int
    ecosystem_id: str | Unset = UNSET
    sync_txid: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        value = self.value

        ecosystem_id = self.ecosystem_id

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "name": name,
                "value": value,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if sync_txid is not UNSET:
            field_dict["syncTxid"] = sync_txid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        value = d.pop("value")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        sync_txid = d.pop("syncTxid", UNSET)

        post_content_counters_body = cls(
            name=name,
            value=value,
            ecosystem_id=ecosystem_id,
            sync_txid=sync_txid,
        )

        return post_content_counters_body
