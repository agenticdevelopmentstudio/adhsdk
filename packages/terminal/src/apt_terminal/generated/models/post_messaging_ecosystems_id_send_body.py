from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_messaging_ecosystems_id_send_body_channel import (
    PostMessagingEcosystemsIdSendBodyChannel,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_messaging_ecosystems_id_send_body_template_vars import (
        PostMessagingEcosystemsIdSendBodyTemplateVars,
    )


T = TypeVar("T", bound="PostMessagingEcosystemsIdSendBody")


@_attrs_define
class PostMessagingEcosystemsIdSendBody:
    """Provide either body or templateId, not both.

    Attributes:
        user_id (str): Target customer id (within this ecosystem)
        channel (PostMessagingEcosystemsIdSendBodyChannel):
        subject (str | Unset): Email subject (freeform)
        body (str | Unset): Freeform message body
        template_id (str | Unset): Template id (alternative to body)
        template_vars (PostMessagingEcosystemsIdSendBodyTemplateVars | Unset): Template placeholder values
        recipient (str | Unset): Override recipient; required for SMS, optional for email
    """

    user_id: str
    channel: PostMessagingEcosystemsIdSendBodyChannel
    subject: str | Unset = UNSET
    body: str | Unset = UNSET
    template_id: str | Unset = UNSET
    template_vars: PostMessagingEcosystemsIdSendBodyTemplateVars | Unset = UNSET
    recipient: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        user_id = self.user_id

        channel = self.channel.value

        subject = self.subject

        body = self.body

        template_id = self.template_id

        template_vars: dict[str, Any] | Unset = UNSET
        if not isinstance(self.template_vars, Unset):
            template_vars = self.template_vars.to_dict()

        recipient = self.recipient

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "userId": user_id,
                "channel": channel,
            }
        )
        if subject is not UNSET:
            field_dict["subject"] = subject
        if body is not UNSET:
            field_dict["body"] = body
        if template_id is not UNSET:
            field_dict["templateId"] = template_id
        if template_vars is not UNSET:
            field_dict["templateVars"] = template_vars
        if recipient is not UNSET:
            field_dict["recipient"] = recipient

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_messaging_ecosystems_id_send_body_template_vars import (
            PostMessagingEcosystemsIdSendBodyTemplateVars,
        )

        d = dict(src_dict)
        user_id = d.pop("userId")

        channel = PostMessagingEcosystemsIdSendBodyChannel(d.pop("channel"))

        subject = d.pop("subject", UNSET)

        body = d.pop("body", UNSET)

        template_id = d.pop("templateId", UNSET)

        _template_vars = d.pop("templateVars", UNSET)
        template_vars: PostMessagingEcosystemsIdSendBodyTemplateVars | Unset
        if isinstance(_template_vars, Unset):
            template_vars = UNSET
        else:
            template_vars = PostMessagingEcosystemsIdSendBodyTemplateVars.from_dict(_template_vars)

        recipient = d.pop("recipient", UNSET)

        post_messaging_ecosystems_id_send_body = cls(
            user_id=user_id,
            channel=channel,
            subject=subject,
            body=body,
            template_id=template_id,
            template_vars=template_vars,
            recipient=recipient,
        )

        post_messaging_ecosystems_id_send_body.additional_properties = d
        return post_messaging_ecosystems_id_send_body

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
