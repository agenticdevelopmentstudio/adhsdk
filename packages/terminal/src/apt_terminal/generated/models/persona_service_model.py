from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PersonaServiceModel")


@_attrs_define
class PersonaServiceModel:
    """
    Attributes:
        id (str): Model id
        available (bool): False when switched off in AI Settings
        offered (bool): False for a switched-off model the provider no longer lists
    """

    id: str
    available: bool
    offered: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        available = self.available

        offered = self.offered

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "available": available,
                "offered": offered,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        available = d.pop("available")

        offered = d.pop("offered")

        persona_service_model = cls(
            id=id,
            available=available,
            offered=offered,
        )

        persona_service_model.additional_properties = d
        return persona_service_model

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
