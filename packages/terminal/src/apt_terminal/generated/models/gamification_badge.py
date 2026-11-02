from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GamificationBadge")


@_attrs_define
class GamificationBadge:
    """
    Attributes:
        id (str):
        name (str):
        description (str):
        icon (str):
        criteria_type (str):
        criteria_threshold (int):
        point_value (int):
        subject_type (None | str | Unset):
    """

    id: str
    name: str
    description: str
    icon: str
    criteria_type: str
    criteria_threshold: int
    point_value: int
    subject_type: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        name = self.name

        description = self.description

        icon = self.icon

        criteria_type = self.criteria_type

        criteria_threshold = self.criteria_threshold

        point_value = self.point_value

        subject_type: None | str | Unset
        if isinstance(self.subject_type, Unset):
            subject_type = UNSET
        else:
            subject_type = self.subject_type

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "description": description,
                "icon": icon,
                "criteriaType": criteria_type,
                "criteriaThreshold": criteria_threshold,
                "pointValue": point_value,
            }
        )
        if subject_type is not UNSET:
            field_dict["subjectType"] = subject_type

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        name = d.pop("name")

        description = d.pop("description")

        icon = d.pop("icon")

        criteria_type = d.pop("criteriaType")

        criteria_threshold = d.pop("criteriaThreshold")

        point_value = d.pop("pointValue")

        def _parse_subject_type(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        subject_type = _parse_subject_type(d.pop("subjectType", UNSET))

        gamification_badge = cls(
            id=id,
            name=name,
            description=description,
            icon=icon,
            criteria_type=criteria_type,
            criteria_threshold=criteria_threshold,
            point_value=point_value,
            subject_type=subject_type,
        )

        gamification_badge.additional_properties = d
        return gamification_badge

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
