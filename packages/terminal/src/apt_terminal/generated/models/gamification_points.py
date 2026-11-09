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
        created (int): Unix timestamp, in seconds.
    """

    id: str
    amount: int
    reason: str
    source_type: str
    source_id: str
    created: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        amount = self.amount

        reason = self.reason

        source_type = self.source_type

        source_id = self.source_id

        created = self.created

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "amount": amount,
                "reason": reason,
                "source_type": source_type,
                "source_id": source_id,
                "created": created,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        amount = d.pop("amount")

        reason = d.pop("reason")

        source_type = d.pop("source_type")

        source_id = d.pop("source_id")

        created = d.pop("created")

        gamification_points = cls(
            id=id,
            amount=amount,
            reason=reason,
            source_type=source_type,
            source_id=source_id,
            created=created,
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
