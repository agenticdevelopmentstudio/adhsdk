from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1MessagingTemplatesResponse200DataItem")


@_attrs_define
class GetV1MessagingTemplatesResponse200DataItem:
    """
    Attributes:
        id (str):
        name (str):
        subject (str):
        html_body (str):
        text_body (str):
        category (str):
        sms_body (str | Unset):
        object_ (Literal['messaging.template'] | Unset):
    """

    id: str
    name: str
    subject: str
    html_body: str
    text_body: str
    category: str
    sms_body: str | Unset = UNSET
    object_: Literal["messaging.template"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        name = self.name

        subject = self.subject

        html_body = self.html_body

        text_body = self.text_body

        category = self.category

        sms_body = self.sms_body

        object_ = self.object_

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
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["messaging.template"] | Unset, d.pop("object", UNSET))
        if object_ != "messaging.template" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'messaging.template', got '{object_}'")

        get_v1_messaging_templates_response_200_data_item = cls(
            id=id,
            name=name,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
            category=category,
            sms_body=sms_body,
            object_=object_,
        )

        get_v1_messaging_templates_response_200_data_item.additional_properties = d
        return get_v1_messaging_templates_response_200_data_item

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
