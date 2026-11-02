from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="ProviderConnectionHeaderVar")


@_attrs_define
class ProviderConnectionHeaderVar:
    """
    Attributes:
        header (str):
        label (str | Unset):
        example (str | Unset):
        secret (bool | Unset):
    """

    header: str
    label: str | Unset = UNSET
    example: str | Unset = UNSET
    secret: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        header = self.header

        label = self.label

        example = self.example

        secret = self.secret

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "header": header,
            }
        )
        if label is not UNSET:
            field_dict["label"] = label
        if example is not UNSET:
            field_dict["example"] = example
        if secret is not UNSET:
            field_dict["secret"] = secret

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        header = d.pop("header")

        label = d.pop("label", UNSET)

        example = d.pop("example", UNSET)

        secret = d.pop("secret", UNSET)

        provider_connection_header_var = cls(
            header=header,
            label=label,
            example=example,
            secret=secret,
        )

        provider_connection_header_var.additional_properties = d
        return provider_connection_header_var

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
