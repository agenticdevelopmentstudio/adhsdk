from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutPersonaMemoryLinksIdBody")


@_attrs_define
class PutPersonaMemoryLinksIdBody:
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
            field_dict["ecosystemId"] = ecosystem_id
        if src_id is not UNSET:
            field_dict["srcId"] = src_id
        if dst_id is not UNSET:
            field_dict["dstId"] = dst_id
        if relation is not UNSET:
            field_dict["relation"] = relation

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystemId", UNSET)

        src_id = d.pop("srcId", UNSET)

        dst_id = d.pop("dstId", UNSET)

        relation = d.pop("relation", UNSET)

        put_persona_memory_links_id_body = cls(
            ecosystem_id=ecosystem_id,
            src_id=src_id,
            dst_id=dst_id,
            relation=relation,
        )

        return put_persona_memory_links_id_body
