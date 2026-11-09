from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.messaging_send_result_status import MessagingSendResultStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1MessagingMessagesResponse200")


@_attrs_define
class PostV1MessagingMessagesResponse200:
    """
    Attributes:
        status (MessagingSendResultStatus):
        provider_id (str | Unset): Provider message id (on success)
        error (str | Unset): Failure reason (on failure)
        object_ (Literal['messaging.message'] | Unset):
    """

    status: MessagingSendResultStatus
    provider_id: str | Unset = UNSET
    error: str | Unset = UNSET
    object_: Literal["messaging.message"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        status = self.status.value

        provider_id = self.provider_id

        error = self.error

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "status": status,
            }
        )
        if provider_id is not UNSET:
            field_dict["provider_id"] = provider_id
        if error is not UNSET:
            field_dict["error"] = error
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        status = MessagingSendResultStatus(d.pop("status"))

        provider_id = d.pop("provider_id", UNSET)

        error = d.pop("error", UNSET)

        object_ = cast(Literal["messaging.message"] | Unset, d.pop("object", UNSET))
        if object_ != "messaging.message" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'messaging.message', got '{object_}'")

        post_v1_messaging_messages_response_200 = cls(
            status=status,
            provider_id=provider_id,
            error=error,
            object_=object_,
        )

        post_v1_messaging_messages_response_200.additional_properties = d
        return post_v1_messaging_messages_response_200

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
