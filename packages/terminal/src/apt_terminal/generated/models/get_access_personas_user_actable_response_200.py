from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.registry_user_actable_persona import RegistryUserActablePersona


T = TypeVar("T", bound="GetAccessPersonasUserActableResponse200")


@_attrs_define
class GetAccessPersonasUserActableResponse200:
    """
    Attributes:
        personas (list[RegistryUserActablePersona]):
    """

    personas: list[RegistryUserActablePersona]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        personas = []
        for personas_item_data in self.personas:
            personas_item = personas_item_data.to_dict()
            personas.append(personas_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "personas": personas,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.registry_user_actable_persona import (
            RegistryUserActablePersona,
        )

        d = dict(src_dict)
        personas = []
        _personas = d.pop("personas")
        for personas_item_data in _personas:
            personas_item = RegistryUserActablePersona.from_dict(personas_item_data)

            personas.append(personas_item)

        get_access_personas_user_actable_response_200 = cls(
            personas=personas,
        )

        get_access_personas_user_actable_response_200.additional_properties = d
        return get_access_personas_user_actable_response_200

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
