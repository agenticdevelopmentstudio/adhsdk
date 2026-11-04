from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostPersonaMemoryLinksBody")


@_attrs_define
class PostPersonaMemoryLinksBody:
    """
    Attributes:
        src_id (str):
        dst_id (str):
        ecosystem_id (str | Unset):
        relation (str | Unset):
    """

    src_id: str
    dst_id: str
    ecosystem_id: str | Unset = UNSET
    relation: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        src_id = self.src_id

        dst_id = self.dst_id

        ecosystem_id = self.ecosystem_id

        relation = self.relation

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "srcId": src_id,
                "dstId": dst_id,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if relation is not UNSET:
            field_dict["relation"] = relation

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        src_id = d.pop("srcId")

        dst_id = d.pop("dstId")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        relation = d.pop("relation", UNSET)

        post_persona_memory_links_body = cls(
            src_id=src_id,
            dst_id=dst_id,
            ecosystem_id=ecosystem_id,
            relation=relation,
        )

        return post_persona_memory_links_body
