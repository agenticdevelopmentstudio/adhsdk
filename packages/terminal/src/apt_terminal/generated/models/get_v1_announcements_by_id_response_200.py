from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1AnnouncementsByIdResponse200")


@_attrs_define
class GetV1AnnouncementsByIdResponse200:
    """
    Attributes:
        id (str):
        created_by (str):
        title (str):
        body (str):
        audience (str): See AnnouncementCreate.audience
        status (str): e.g. sending, sent
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sent_at (None | str): null until the fan-out finishes
        total_recipients (int):
        sent_count (int):
        object_ (Literal['announcement'] | Unset):
    """

    id: str
    created_by: str
    title: str
    body: str
    audience: str
    status: str
    created: int
    updated: int
    sent_at: None | str
    total_recipients: int
    sent_count: int
    object_: Literal["announcement"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        created_by = self.created_by

        title = self.title

        body = self.body

        audience = self.audience

        status = self.status

        created = self.created

        updated = self.updated

        sent_at: None | str
        sent_at = self.sent_at

        total_recipients = self.total_recipients

        sent_count = self.sent_count

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "created_by": created_by,
                "title": title,
                "body": body,
                "audience": audience,
                "status": status,
                "created": created,
                "updated": updated,
                "sent_at": sent_at,
                "total_recipients": total_recipients,
                "sent_count": sent_count,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        created_by = d.pop("created_by")

        title = d.pop("title")

        body = d.pop("body")

        audience = d.pop("audience")

        status = d.pop("status")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_sent_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sent_at = _parse_sent_at(d.pop("sent_at"))

        total_recipients = d.pop("total_recipients")

        sent_count = d.pop("sent_count")

        object_ = cast(Literal["announcement"] | Unset, d.pop("object", UNSET))
        if object_ != "announcement" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'announcement', got '{object_}'")

        get_v1_announcements_by_id_response_200 = cls(
            id=id,
            created_by=created_by,
            title=title,
            body=body,
            audience=audience,
            status=status,
            created=created,
            updated=updated,
            sent_at=sent_at,
            total_recipients=total_recipients,
            sent_count=sent_count,
            object_=object_,
        )

        get_v1_announcements_by_id_response_200.additional_properties = d
        return get_v1_announcements_by_id_response_200

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
