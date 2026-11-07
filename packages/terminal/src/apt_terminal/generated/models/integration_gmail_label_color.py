from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="IntegrationGmailLabelColor")


@_attrs_define
class IntegrationGmailLabelColor:
    """
    Attributes:
        text_color (str):
        background_color (str):
    """

    text_color: str
    background_color: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        text_color = self.text_color

        background_color = self.background_color

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "textColor": text_color,
                "backgroundColor": background_color,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        text_color = d.pop("textColor")

        background_color = d.pop("backgroundColor")

        integration_gmail_label_color = cls(
            text_color=text_color,
            background_color=background_color,
        )

        integration_gmail_label_color.additional_properties = d
        return integration_gmail_label_color

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
