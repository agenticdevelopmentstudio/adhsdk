from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.messaging_send_result_status import MessagingSendResultStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="MessagingSendResult")


@_attrs_define
class MessagingSendResult:
    """
    Attributes:
        status (MessagingSendResultStatus):
        provider_id (str | Unset): Provider message id (on success)
        error (str | Unset): Failure reason (on failure)
    """

    status: MessagingSendResultStatus
    provider_id: str | Unset = UNSET
    error: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        status = self.status.value

        provider_id = self.provider_id

        error = self.error

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "status": status,
            }
        )
        if provider_id is not UNSET:
            field_dict["providerId"] = provider_id
        if error is not UNSET:
            field_dict["error"] = error

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        status = MessagingSendResultStatus(d.pop("status"))

        provider_id = d.pop("providerId", UNSET)

        error = d.pop("error", UNSET)

        messaging_send_result = cls(
            status=status,
            provider_id=provider_id,
            error=error,
        )

        messaging_send_result.additional_properties = d
        return messaging_send_result

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
