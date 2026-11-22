from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define

T = TypeVar("T", bound="SetMembersPut")


@_attrs_define
class SetMembersPut:
    """
    Attributes:
        contains (list[UUID]):
    """

    contains: list[UUID]

    def to_dict(self) -> dict[str, Any]:
        contains = []
        for contains_item_data in self.contains:
            contains_item = str(contains_item_data)
            contains.append(contains_item)

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "contains": contains,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        contains = []
        _contains = d.pop("contains")
        for contains_item_data in _contains:
            contains_item = UUID(contains_item_data)

            contains.append(contains_item)

        set_members_put = cls(
            contains=contains,
        )

        return set_members_put
