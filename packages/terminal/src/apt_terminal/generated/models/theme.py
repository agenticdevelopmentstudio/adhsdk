from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.theme_data import ThemeData


T = TypeVar("T", bound="Theme")


@_attrs_define
class Theme:
    """
    Attributes:
        key (str):
        label (str):
        based_on (None | str):
        data (ThemeData):
        created_at (str):
        updated_at (str):
    """

    key: str
    label: str
    based_on: None | str
    data: ThemeData
    created_at: str
    updated_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        label = self.label

        based_on: None | str
        based_on = self.based_on

        data = self.data.to_dict()

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "label": label,
                "basedOn": based_on,
                "data": data,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.theme_data import ThemeData

        d = dict(src_dict)
        key = d.pop("key")

        label = d.pop("label")

        def _parse_based_on(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        based_on = _parse_based_on(d.pop("basedOn"))

        data = ThemeData.from_dict(d.pop("data"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        theme = cls(
            key=key,
            label=label,
            based_on=based_on,
            data=data,
            created_at=created_at,
            updated_at=updated_at,
        )

        theme.additional_properties = d
        return theme

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
