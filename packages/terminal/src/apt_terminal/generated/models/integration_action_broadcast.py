from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="IntegrationActionBroadcast")


@_attrs_define
class IntegrationActionBroadcast:
    """actionType=broadcast — compose (but do NOT send) a broadcast to an audience; returns the broadcast id

    Attributes:
        audience_id (str): Provider list id
        subject (str):
        body_html (str):
        from_name (str | Unset):
        reply_to (str | Unset):
        body_text (str | Unset):
    """

    audience_id: str
    subject: str
    body_html: str
    from_name: str | Unset = UNSET
    reply_to: str | Unset = UNSET
    body_text: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        audience_id = self.audience_id

        subject = self.subject

        body_html = self.body_html

        from_name = self.from_name

        reply_to = self.reply_to

        body_text = self.body_text

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "audienceId": audience_id,
                "subject": subject,
                "bodyHtml": body_html,
            }
        )
        if from_name is not UNSET:
            field_dict["fromName"] = from_name
        if reply_to is not UNSET:
            field_dict["replyTo"] = reply_to
        if body_text is not UNSET:
            field_dict["bodyText"] = body_text

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        audience_id = d.pop("audienceId")

        subject = d.pop("subject")

        body_html = d.pop("bodyHtml")

        from_name = d.pop("fromName", UNSET)

        reply_to = d.pop("replyTo", UNSET)

        body_text = d.pop("bodyText", UNSET)

        integration_action_broadcast = cls(
            audience_id=audience_id,
            subject=subject,
            body_html=body_html,
            from_name=from_name,
            reply_to=reply_to,
            body_text=body_text,
        )

        integration_action_broadcast.additional_properties = d
        return integration_action_broadcast

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
