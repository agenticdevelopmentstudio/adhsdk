from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="IntegrationProviderConfigFieldsItem")


@_attrs_define
class IntegrationProviderConfigFieldsItem:
    """
    Attributes:
        key (str):
        label (str):
        secret (bool):
        required (bool):
        placeholder (str | Unset):
    """

    key: str
    label: str
    secret: bool
    required: bool
    placeholder: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        label = self.label

        secret = self.secret

        required = self.required

        placeholder = self.placeholder

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "label": label,
                "secret": secret,
                "required": required,
            }
        )
        if placeholder is not UNSET:
            field_dict["placeholder"] = placeholder

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key")

        label = d.pop("label")

        secret = d.pop("secret")

        required = d.pop("required")

        placeholder = d.pop("placeholder", UNSET)

        integration_provider_config_fields_item = cls(
            key=key,
            label=label,
            secret=secret,
            required=required,
            placeholder=placeholder,
        )

        integration_provider_config_fields_item.additional_properties = d
        return integration_provider_config_fields_item

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
