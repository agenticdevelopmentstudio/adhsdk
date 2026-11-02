from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.registry_entry_value_visibility_additional_property import (
    RegistryEntryValueVisibilityAdditionalProperty,
)

T = TypeVar("T", bound="RegistryEntryValueVisibility")


@_attrs_define
class RegistryEntryValueVisibility:
    """the registrant's per-field audience overrides, keyed by field_defs.key; a key is absent when the field simply
    follows its def. Never wider than the def allows AS STORED, but read it as the tighter of the two anyway — the
    owner's ceiling can move after this map is written

    """

    additional_properties: dict[str, RegistryEntryValueVisibilityAdditionalProperty] = _attrs_field(
        init=False, factory=dict
    )

    def to_dict(self) -> dict[str, Any]:
        field_dict: dict[str, Any] = {}
        for prop_name, prop in self.additional_properties.items():
            field_dict[prop_name] = prop.value

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        registry_entry_value_visibility = cls()

        additional_properties = {}
        for prop_name, prop_dict in d.items():
            additional_property = RegistryEntryValueVisibilityAdditionalProperty(prop_dict)

            additional_properties[prop_name] = additional_property

        registry_entry_value_visibility.additional_properties = additional_properties
        return registry_entry_value_visibility

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> RegistryEntryValueVisibilityAdditionalProperty:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: RegistryEntryValueVisibilityAdditionalProperty) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
