from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.announcement_accepted_status import AnnouncementAcceptedStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AnnouncementsResponse202")


@_attrs_define
class PostV1AnnouncementsResponse202:
    """
    Attributes:
        id (str):
        recipient_count (int):
        status (AnnouncementAcceptedStatus):
        object_ (Literal['announcement'] | Unset):
    """

    id: str
    recipient_count: int
    status: AnnouncementAcceptedStatus
    object_: Literal["announcement"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        recipient_count = self.recipient_count

        status = self.status.value

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "recipient_count": recipient_count,
                "status": status,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        recipient_count = d.pop("recipient_count")

        status = AnnouncementAcceptedStatus(d.pop("status"))

        object_ = cast(Literal["announcement"] | Unset, d.pop("object", UNSET))
        if object_ != "announcement" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'announcement', got '{object_}'")

        post_v1_announcements_response_202 = cls(
            id=id,
            recipient_count=recipient_count,
            status=status,
            object_=object_,
        )

        post_v1_announcements_response_202.additional_properties = d
        return post_v1_announcements_response_202

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
