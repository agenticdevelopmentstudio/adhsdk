from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1GamificationLevelsResponse200DataItem")


@_attrs_define
class GetV1GamificationLevelsResponse200DataItem:
    """
    Attributes:
        name (str):
        min_points (int): Inclusive point floor for this rung
        sort_order (int):
        subject_type (None | str | Unset): NULL = applies to any subject kind
        object_ (Literal['gamification.level'] | Unset):
    """

    name: str
    min_points: int
    sort_order: int
    subject_type: None | str | Unset = UNSET
    object_: Literal["gamification.level"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        min_points = self.min_points

        sort_order = self.sort_order

        subject_type: None | str | Unset
        if isinstance(self.subject_type, Unset):
            subject_type = UNSET
        else:
            subject_type = self.subject_type

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
                "min_points": min_points,
                "sort_order": sort_order,
            }
        )
        if subject_type is not UNSET:
            field_dict["subject_type"] = subject_type
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        min_points = d.pop("min_points")

        sort_order = d.pop("sort_order")

        def _parse_subject_type(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        subject_type = _parse_subject_type(d.pop("subject_type", UNSET))

        object_ = cast(Literal["gamification.level"] | Unset, d.pop("object", UNSET))
        if object_ != "gamification.level" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'gamification.level', got '{object_}'")

        get_v1_gamification_levels_response_200_data_item = cls(
            name=name,
            min_points=min_points,
            sort_order=sort_order,
            subject_type=subject_type,
            object_=object_,
        )

        get_v1_gamification_levels_response_200_data_item.additional_properties = d
        return get_v1_gamification_levels_response_200_data_item

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
