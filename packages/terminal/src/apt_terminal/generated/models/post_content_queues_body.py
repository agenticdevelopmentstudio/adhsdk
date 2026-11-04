from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostContentQueuesBody")


@_attrs_define
class PostContentQueuesBody:
    """
    Attributes:
        name (str):
        ecosystem_id (str | Unset):
    """

    name: str
    ecosystem_id: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        ecosystem_id = self.ecosystem_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "name": name,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        post_content_queues_body = cls(
            name=name,
            ecosystem_id=ecosystem_id,
        )

        return post_content_queues_body
