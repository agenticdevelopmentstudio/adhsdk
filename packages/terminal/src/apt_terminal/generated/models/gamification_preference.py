from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="GamificationPreference")


@_attrs_define
class GamificationPreference:
    """
    Attributes:
        subject_type (str):
        subject_id (str):
        opted_out (bool):
    """

    subject_type: str
    subject_id: str
    opted_out: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subject_type = self.subject_type

        subject_id = self.subject_id

        opted_out = self.opted_out

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subject_type": subject_type,
                "subject_id": subject_id,
                "opted_out": opted_out,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        subject_type = d.pop("subject_type")

        subject_id = d.pop("subject_id")

        opted_out = d.pop("opted_out")

        gamification_preference = cls(
            subject_type=subject_type,
            subject_id=subject_id,
            opted_out=opted_out,
        )

        gamification_preference.additional_properties = d
        return gamification_preference

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
