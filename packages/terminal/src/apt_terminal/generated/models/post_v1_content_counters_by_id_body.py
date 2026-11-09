from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ContentCountersByIdBody")


@_attrs_define
class PostV1ContentCountersByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        name (str | Unset):
        value (int | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    name: str | Unset = UNSET
    value: int | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        name = self.name

        value = self.value

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if name is not UNSET:
            field_dict["name"] = name
        if value is not UNSET:
            field_dict["value"] = value

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        name = d.pop("name", UNSET)

        value = d.pop("value", UNSET)

        post_v1_content_counters_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            name=name,
            value=value,
        )

        return post_v1_content_counters_by_id_body
