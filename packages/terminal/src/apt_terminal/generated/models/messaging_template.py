from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="MessagingTemplate")


@_attrs_define
class MessagingTemplate:
    """
    Attributes:
        id (str):
        name (str):
        subject (str):
        html_body (str):
        text_body (str):
        category (str):
        sms_body (str | Unset):
    """

    id: str
    name: str
    subject: str
    html_body: str
    text_body: str
    category: str
    sms_body: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        name = self.name

        subject = self.subject

        html_body = self.html_body

        text_body = self.text_body

        category = self.category

        sms_body = self.sms_body

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "subject": subject,
                "html_body": html_body,
                "text_body": text_body,
                "category": category,
            }
        )
        if sms_body is not UNSET:
            field_dict["sms_body"] = sms_body

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        name = d.pop("name")

        subject = d.pop("subject")

        html_body = d.pop("html_body")

        text_body = d.pop("text_body")

        category = d.pop("category")

        sms_body = d.pop("sms_body", UNSET)

        messaging_template = cls(
            id=id,
            name=name,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
            category=category,
            sms_body=sms_body,
        )

        messaging_template.additional_properties = d
        return messaging_template

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
