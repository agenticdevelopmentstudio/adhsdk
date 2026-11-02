from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="GamificationPoints")


@_attrs_define
class GamificationPoints:
    """
    Attributes:
        id (str):
        amount (int):
        reason (str):
        source_type (str):
        source_id (str):
        created_at (str):
    """

    id: str
    amount: int
    reason: str
    source_type: str
    source_id: str
    created_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        amount = self.amount

        reason = self.reason

        source_type = self.source_type

        source_id = self.source_id

        created_at = self.created_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "amount": amount,
                "reason": reason,
                "sourceType": source_type,
                "sourceId": source_id,
                "createdAt": created_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        amount = d.pop("amount")

        reason = d.pop("reason")

        source_type = d.pop("sourceType")

        source_id = d.pop("sourceId")

        created_at = d.pop("createdAt")

        gamification_points = cls(
            id=id,
            amount=amount,
            reason=reason,
            source_type=source_type,
            source_id=source_id,
            created_at=created_at,
        )

        gamification_points.additional_properties = d
        return gamification_points

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
