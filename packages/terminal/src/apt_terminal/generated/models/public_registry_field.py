from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.public_registry_field_visibility import PublicRegistryFieldVisibility

T = TypeVar("T", bound="PublicRegistryField")


@_attrs_define
class PublicRegistryField:
    """
    Attributes:
        key (str):
        label (str):
        type_ (str):
        value (Any):
        visibility (PublicRegistryFieldVisibility): The EFFECTIVE audience for this value — the tighter of the registry
            owner’s ceiling for the field and the registrant’s own override on this entry. A client renders it as the "who
            can see this" marker; it is not the def’s configured setting, which may be wider.
    """

    key: str
    label: str
    type_: str
    value: Any
    visibility: PublicRegistryFieldVisibility
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        label = self.label

        type_ = self.type_

        value = self.value

        visibility = self.visibility.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "label": label,
                "type": type_,
                "value": value,
                "visibility": visibility,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key")

        label = d.pop("label")

        type_ = d.pop("type")

        value = d.pop("value")

        visibility = PublicRegistryFieldVisibility(d.pop("visibility"))

        public_registry_field = cls(
            key=key,
            label=label,
            type_=type_,
            value=value,
            visibility=visibility,
        )

        public_registry_field.additional_properties = d
        return public_registry_field

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
