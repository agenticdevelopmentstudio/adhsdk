from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostmarkDeliverabilityEvent")


@_attrs_define
class PostmarkDeliverabilityEvent:
    """
    Attributes:
        record_type (str): 'Bounce' | 'SpamComplaint' | 'SubscriptionChange' | anything else (ignored)
        type_ (str | Unset): e.g. 'HardBounce', 'SoftBounce', 'BadEmailAddress'
        email (str | Unset):
        recipient (str | Unset):
        description (str | Unset):
        suppress_sending (bool | Unset): Only meaningful on a 'SubscriptionChange' event: Postmark sends this both when
            an address ENTERS its suppression list (true) and when it LEAVES (false). Only true suppresses — acting on false
            would permanently silence a re-subscribe.
    """

    record_type: str
    type_: str | Unset = UNSET
    email: str | Unset = UNSET
    recipient: str | Unset = UNSET
    description: str | Unset = UNSET
    suppress_sending: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        record_type = self.record_type

        type_ = self.type_

        email = self.email

        recipient = self.recipient

        description = self.description

        suppress_sending = self.suppress_sending

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "RecordType": record_type,
            }
        )
        if type_ is not UNSET:
            field_dict["Type"] = type_
        if email is not UNSET:
            field_dict["Email"] = email
        if recipient is not UNSET:
            field_dict["Recipient"] = recipient
        if description is not UNSET:
            field_dict["Description"] = description
        if suppress_sending is not UNSET:
            field_dict["SuppressSending"] = suppress_sending

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        record_type = d.pop("RecordType")

        type_ = d.pop("Type", UNSET)

        email = d.pop("Email", UNSET)

        recipient = d.pop("Recipient", UNSET)

        description = d.pop("Description", UNSET)

        suppress_sending = d.pop("SuppressSending", UNSET)

        postmark_deliverability_event = cls(
            record_type=record_type,
            type_=type_,
            email=email,
            recipient=recipient,
            description=description,
            suppress_sending=suppress_sending,
        )

        postmark_deliverability_event.additional_properties = d
        return postmark_deliverability_event

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
