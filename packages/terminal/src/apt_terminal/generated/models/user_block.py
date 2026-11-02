from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="UserBlock")


@_attrs_define
class UserBlock:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        blocker_id (str):
        blocked_id (str):
        created_at (str):
    """

    id: str
    ecosystem_id: str
    blocker_id: str
    blocked_id: str
    created_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        blocker_id = self.blocker_id

        blocked_id = self.blocked_id

        created_at = self.created_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "blockerId": blocker_id,
                "blockedId": blocked_id,
                "createdAt": created_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        blocker_id = d.pop("blockerId")

        blocked_id = d.pop("blockedId")

        created_at = d.pop("createdAt")

        user_block = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            blocker_id=blocker_id,
            blocked_id=blocked_id,
            created_at=created_at,
        )

        user_block.additional_properties = d
        return user_block

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
