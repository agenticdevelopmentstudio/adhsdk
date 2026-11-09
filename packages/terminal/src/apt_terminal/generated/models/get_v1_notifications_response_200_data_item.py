from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.notification_status import NotificationStatus
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.notification_data import NotificationData


T = TypeVar("T", bound="GetV1NotificationsResponse200DataItem")


@_attrs_define
class GetV1NotificationsResponse200DataItem:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        user_id (str):
        category (str):
        title (str):
        data (NotificationData):
        status (NotificationStatus):
        is_read (bool):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        actor_id (None | str | Unset):
        entity_kind (None | str | Unset):
        entity_id (None | str | Unset):
        body (None | str | Unset):
        dedupe_key (None | str | Unset):
        read_at (None | str | Unset):
        object_ (Literal['notification'] | Unset):
    """

    id: str
    ecosystem_id: str
    user_id: str
    category: str
    title: str
    data: NotificationData
    status: NotificationStatus
    is_read: bool
    created: int
    updated: int
    actor_id: None | str | Unset = UNSET
    entity_kind: None | str | Unset = UNSET
    entity_id: None | str | Unset = UNSET
    body: None | str | Unset = UNSET
    dedupe_key: None | str | Unset = UNSET
    read_at: None | str | Unset = UNSET
    object_: Literal["notification"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        user_id = self.user_id

        category = self.category

        title = self.title

        data = self.data.to_dict()

        status = self.status.value

        is_read = self.is_read

        created = self.created

        updated = self.updated

        actor_id: None | str | Unset
        if isinstance(self.actor_id, Unset):
            actor_id = UNSET
        else:
            actor_id = self.actor_id

        entity_kind: None | str | Unset
        if isinstance(self.entity_kind, Unset):
            entity_kind = UNSET
        else:
            entity_kind = self.entity_kind

        entity_id: None | str | Unset
        if isinstance(self.entity_id, Unset):
            entity_id = UNSET
        else:
            entity_id = self.entity_id

        body: None | str | Unset
        if isinstance(self.body, Unset):
            body = UNSET
        else:
            body = self.body

        dedupe_key: None | str | Unset
        if isinstance(self.dedupe_key, Unset):
            dedupe_key = UNSET
        else:
            dedupe_key = self.dedupe_key

        read_at: None | str | Unset
        if isinstance(self.read_at, Unset):
            read_at = UNSET
        else:
            read_at = self.read_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "user_id": user_id,
                "category": category,
                "title": title,
                "data": data,
                "status": status,
                "is_read": is_read,
                "created": created,
                "updated": updated,
            }
        )
        if actor_id is not UNSET:
            field_dict["actor_id"] = actor_id
        if entity_kind is not UNSET:
            field_dict["entity_kind"] = entity_kind
        if entity_id is not UNSET:
            field_dict["entity_id"] = entity_id
        if body is not UNSET:
            field_dict["body"] = body
        if dedupe_key is not UNSET:
            field_dict["dedupe_key"] = dedupe_key
        if read_at is not UNSET:
            field_dict["read_at"] = read_at
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.notification_data import NotificationData

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        user_id = d.pop("user_id")

        category = d.pop("category")

        title = d.pop("title")

        data = NotificationData.from_dict(d.pop("data"))

        status = NotificationStatus(d.pop("status"))

        is_read = d.pop("is_read")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_actor_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        actor_id = _parse_actor_id(d.pop("actor_id", UNSET))

        def _parse_entity_kind(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        entity_kind = _parse_entity_kind(d.pop("entity_kind", UNSET))

        def _parse_entity_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        entity_id = _parse_entity_id(d.pop("entity_id", UNSET))

        def _parse_body(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        body = _parse_body(d.pop("body", UNSET))

        def _parse_dedupe_key(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        dedupe_key = _parse_dedupe_key(d.pop("dedupe_key", UNSET))

        def _parse_read_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        read_at = _parse_read_at(d.pop("read_at", UNSET))

        object_ = cast(Literal["notification"] | Unset, d.pop("object", UNSET))
        if object_ != "notification" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'notification', got '{object_}'")

        get_v1_notifications_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            user_id=user_id,
            category=category,
            title=title,
            data=data,
            status=status,
            is_read=is_read,
            created=created,
            updated=updated,
            actor_id=actor_id,
            entity_kind=entity_kind,
            entity_id=entity_id,
            body=body,
            dedupe_key=dedupe_key,
            read_at=read_at,
            object_=object_,
        )

        get_v1_notifications_response_200_data_item.additional_properties = d
        return get_v1_notifications_response_200_data_item

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
