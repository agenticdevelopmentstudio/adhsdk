from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.announcement_accepted_status import AnnouncementAcceptedStatus

T = TypeVar("T", bound="AnnouncementAccepted")


@_attrs_define
class AnnouncementAccepted:
    """
    Attributes:
        id (str):
        recipient_count (int):
        status (AnnouncementAcceptedStatus):
    """

    id: str
    recipient_count: int
    status: AnnouncementAcceptedStatus
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        recipient_count = self.recipient_count

        status = self.status.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "recipient_count": recipient_count,
                "status": status,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        recipient_count = d.pop("recipient_count")

        status = AnnouncementAcceptedStatus(d.pop("status"))

        announcement_accepted = cls(
            id=id,
            recipient_count=recipient_count,
            status=status,
        )

        announcement_accepted.additional_properties = d
        return announcement_accepted

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
