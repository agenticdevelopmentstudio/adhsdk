from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AuditEventsByIdResponse200")


@_attrs_define
class PostV1AuditEventsByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (None | str):
        developer_id (None | str):
        actor_user_id (None | str):
        event_type (str):
        payload (str):
        ip_address (str):
        user_agent (str):
        created (int): Unix timestamp, in seconds.
        object_ (Literal['audit_event'] | Unset):
    """

    id: str
    ecosystem_id: None | str
    developer_id: None | str
    actor_user_id: None | str
    event_type: str
    payload: str
    ip_address: str
    user_agent: str
    created: int
    object_: Literal["audit_event"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id: None | str
        ecosystem_id = self.ecosystem_id

        developer_id: None | str
        developer_id = self.developer_id

        actor_user_id: None | str
        actor_user_id = self.actor_user_id

        event_type = self.event_type

        payload = self.payload

        ip_address = self.ip_address

        user_agent = self.user_agent

        created = self.created

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "developer_id": developer_id,
                "actor_user_id": actor_user_id,
                "event_type": event_type,
                "payload": payload,
                "ip_address": ip_address,
                "user_agent": user_agent,
                "created": created,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        def _parse_ecosystem_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        ecosystem_id = _parse_ecosystem_id(d.pop("ecosystem_id"))

        def _parse_developer_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        developer_id = _parse_developer_id(d.pop("developer_id"))

        def _parse_actor_user_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        actor_user_id = _parse_actor_user_id(d.pop("actor_user_id"))

        event_type = d.pop("event_type")

        payload = d.pop("payload")

        ip_address = d.pop("ip_address")

        user_agent = d.pop("user_agent")

        created = d.pop("created")

        object_ = cast(Literal["audit_event"] | Unset, d.pop("object", UNSET))
        if object_ != "audit_event" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'audit_event', got '{object_}'")

        post_v1_audit_events_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            developer_id=developer_id,
            actor_user_id=actor_user_id,
            event_type=event_type,
            payload=payload,
            ip_address=ip_address,
            user_agent=user_agent,
            created=created,
            object_=object_,
        )

        return post_v1_audit_events_by_id_response_200
