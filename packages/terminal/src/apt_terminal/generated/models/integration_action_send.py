from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="IntegrationActionSend")


@_attrs_define
class IntegrationActionSend:
    """actionType=send — an outbound email; at least one body is required

    Attributes:
        to (list[str]):
        subject (str):
        cc (list[str] | Unset):
        bcc (list[str] | Unset):
        body_text (str | Unset):
        body_html (str | Unset):
    """

    to: list[str]
    subject: str
    cc: list[str] | Unset = UNSET
    bcc: list[str] | Unset = UNSET
    body_text: str | Unset = UNSET
    body_html: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        to = self.to

        subject = self.subject

        cc: list[str] | Unset = UNSET
        if not isinstance(self.cc, Unset):
            cc = self.cc

        bcc: list[str] | Unset = UNSET
        if not isinstance(self.bcc, Unset):
            bcc = self.bcc

        body_text = self.body_text

        body_html = self.body_html

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "to": to,
                "subject": subject,
            }
        )
        if cc is not UNSET:
            field_dict["cc"] = cc
        if bcc is not UNSET:
            field_dict["bcc"] = bcc
        if body_text is not UNSET:
            field_dict["body_text"] = body_text
        if body_html is not UNSET:
            field_dict["body_html"] = body_html

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        to = cast(list[str], d.pop("to"))

        subject = d.pop("subject")

        cc = cast(list[str], d.pop("cc", UNSET))

        bcc = cast(list[str], d.pop("bcc", UNSET))

        body_text = d.pop("body_text", UNSET)

        body_html = d.pop("body_html", UNSET)

        integration_action_send = cls(
            to=to,
            subject=subject,
            cc=cc,
            bcc=bcc,
            body_text=body_text,
            body_html=body_html,
        )

        integration_action_send.additional_properties = d
        return integration_action_send

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
