from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.delivery_status import DeliveryStatus

T = TypeVar("T", bound="Delivery")


@_attrs_define
class Delivery:
    """
    Attributes:
        id (str):
        email (str):
        name (None | str):
        status (DeliveryStatus):
        attempts (int):
        last_error (None | str):
        sent_at (None | str):
    """

    id: str
    email: str
    name: None | str
    status: DeliveryStatus
    attempts: int
    last_error: None | str
    sent_at: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        email = self.email

        name: None | str
        name = self.name

        status = self.status.value

        attempts = self.attempts

        last_error: None | str
        last_error = self.last_error

        sent_at: None | str
        sent_at = self.sent_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "email": email,
                "name": name,
                "status": status,
                "attempts": attempts,
                "lastError": last_error,
                "sentAt": sent_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        email = d.pop("email")

        def _parse_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        name = _parse_name(d.pop("name"))

        status = DeliveryStatus(d.pop("status"))

        attempts = d.pop("attempts")

        def _parse_last_error(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_error = _parse_last_error(d.pop("lastError"))

        def _parse_sent_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sent_at = _parse_sent_at(d.pop("sentAt"))

        delivery = cls(
            id=id,
            email=email,
            name=name,
            status=status,
            attempts=attempts,
            last_error=last_error,
            sent_at=sent_at,
        )

        delivery.additional_properties = d
        return delivery

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
