from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1MessagingStatusResponse200")


@_attrs_define
class GetV1MessagingStatusResponse200:
    """
    Attributes:
        email (bool): Postmark configured + enabled
        sms (bool): Twilio configured + enabled
        object_ (Literal['messaging.status'] | Unset):
    """

    email: bool
    sms: bool
    object_: Literal["messaging.status"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        email = self.email

        sms = self.sms

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "email": email,
                "sms": sms,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        email = d.pop("email")

        sms = d.pop("sms")

        object_ = cast(Literal["messaging.status"] | Unset, d.pop("object", UNSET))
        if object_ != "messaging.status" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'messaging.status', got '{object_}'")

        get_v1_messaging_status_response_200 = cls(
            email=email,
            sms=sms,
            object_=object_,
        )

        get_v1_messaging_status_response_200.additional_properties = d
        return get_v1_messaging_status_response_200

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
