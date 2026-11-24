from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1GamificationAwardsBody")


@_attrs_define
class PostV1GamificationAwardsBody:
    """
    Attributes:
        subject_type (str):
        subject_id (str):
        amount (int):
        reason (str):
        source_type (str | Unset):
        source_id (str | Unset):
    """

    subject_type: str
    subject_id: str
    amount: int
    reason: str
    source_type: str | Unset = UNSET
    source_id: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subject_type = self.subject_type

        subject_id = self.subject_id

        amount = self.amount

        reason = self.reason

        source_type = self.source_type

        source_id = self.source_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subject_type": subject_type,
                "subject_id": subject_id,
                "amount": amount,
                "reason": reason,
            }
        )
        if source_type is not UNSET:
            field_dict["source_type"] = source_type
        if source_id is not UNSET:
            field_dict["source_id"] = source_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        subject_type = d.pop("subject_type")

        subject_id = d.pop("subject_id")

        amount = d.pop("amount")

        reason = d.pop("reason")

        source_type = d.pop("source_type", UNSET)

        source_id = d.pop("source_id", UNSET)

        post_v1_gamification_awards_body = cls(
            subject_type=subject_type,
            subject_id=subject_id,
            amount=amount,
            reason=reason,
            source_type=source_type,
            source_id=source_id,
        )

        post_v1_gamification_awards_body.additional_properties = d
        return post_v1_gamification_awards_body

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
