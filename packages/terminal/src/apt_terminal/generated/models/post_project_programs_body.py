from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostProjectProgramsBody")


@_attrs_define
class PostProjectProgramsBody:
    """
    Attributes:
        name (str): unique among the workspace’s live programs (409 otherwise)
        description (str | Unset):
        color (str | Unset):
        start_date (None | str | Unset): date (YYYY-MM-DD); optional, UNLIKE an iteration — a program need not be a
            time-box
        target_date (None | str | Unset): date (YYYY-MM-DD); 400 if it precedes startDate
    """

    name: str
    description: str | Unset = UNSET
    color: str | Unset = UNSET
    start_date: None | str | Unset = UNSET
    target_date: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        description = self.description

        color = self.color

        start_date: None | str | Unset
        if isinstance(self.start_date, Unset):
            start_date = UNSET
        else:
            start_date = self.start_date

        target_date: None | str | Unset
        if isinstance(self.target_date, Unset):
            target_date = UNSET
        else:
            target_date = self.target_date

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if color is not UNSET:
            field_dict["color"] = color
        if start_date is not UNSET:
            field_dict["startDate"] = start_date
        if target_date is not UNSET:
            field_dict["targetDate"] = target_date

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        description = d.pop("description", UNSET)

        color = d.pop("color", UNSET)

        def _parse_start_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        start_date = _parse_start_date(d.pop("startDate", UNSET))

        def _parse_target_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        target_date = _parse_target_date(d.pop("targetDate", UNSET))

        post_project_programs_body = cls(
            name=name,
            description=description,
            color=color,
            start_date=start_date,
            target_date=target_date,
        )

        post_project_programs_body.additional_properties = d
        return post_project_programs_body

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
