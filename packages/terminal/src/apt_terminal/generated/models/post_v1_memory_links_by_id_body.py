from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1MemoryLinksByIdBody")


@_attrs_define
class PostV1MemoryLinksByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        src_id (str | Unset):
        dst_id (str | Unset):
        relation (str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    src_id: str | Unset = UNSET
    dst_id: str | Unset = UNSET
    relation: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        src_id = self.src_id

        dst_id = self.dst_id

        relation = self.relation

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if src_id is not UNSET:
            field_dict["src_id"] = src_id
        if dst_id is not UNSET:
            field_dict["dst_id"] = dst_id
        if relation is not UNSET:
            field_dict["relation"] = relation

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        src_id = d.pop("src_id", UNSET)

        dst_id = d.pop("dst_id", UNSET)

        relation = d.pop("relation", UNSET)

        post_v1_memory_links_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            src_id=src_id,
            dst_id=dst_id,
            relation=relation,
        )

        return post_v1_memory_links_by_id_body
