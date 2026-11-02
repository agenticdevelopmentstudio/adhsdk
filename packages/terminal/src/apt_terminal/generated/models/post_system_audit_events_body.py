from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostSystemAuditEventsBody")


@_attrs_define
class PostSystemAuditEventsBody:
    """
    Attributes:
        event_type (str):
        ecosystem_id (None | str | Unset):
        developer_id (None | str | Unset):
        actor_user_id (None | str | Unset):
        payload (str | Unset):
        ip_address (str | Unset):
        user_agent (str | Unset):
    """

    event_type: str
    ecosystem_id: None | str | Unset = UNSET
    developer_id: None | str | Unset = UNSET
    actor_user_id: None | str | Unset = UNSET
    payload: str | Unset = UNSET
    ip_address: str | Unset = UNSET
    user_agent: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        event_type = self.event_type

        ecosystem_id: None | str | Unset
        if isinstance(self.ecosystem_id, Unset):
            ecosystem_id = UNSET
        else:
            ecosystem_id = self.ecosystem_id

        developer_id: None | str | Unset
        if isinstance(self.developer_id, Unset):
            developer_id = UNSET
        else:
            developer_id = self.developer_id

        actor_user_id: None | str | Unset
        if isinstance(self.actor_user_id, Unset):
            actor_user_id = UNSET
        else:
            actor_user_id = self.actor_user_id

        payload = self.payload

        ip_address = self.ip_address

        user_agent = self.user_agent

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "eventType": event_type,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if developer_id is not UNSET:
            field_dict["developerId"] = developer_id
        if actor_user_id is not UNSET:
            field_dict["actorUserId"] = actor_user_id
        if payload is not UNSET:
            field_dict["payload"] = payload
        if ip_address is not UNSET:
            field_dict["ipAddress"] = ip_address
        if user_agent is not UNSET:
            field_dict["userAgent"] = user_agent

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        event_type = d.pop("eventType")

        def _parse_ecosystem_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        ecosystem_id = _parse_ecosystem_id(d.pop("ecosystemId", UNSET))

        def _parse_developer_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        developer_id = _parse_developer_id(d.pop("developerId", UNSET))

        def _parse_actor_user_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        actor_user_id = _parse_actor_user_id(d.pop("actorUserId", UNSET))

        payload = d.pop("payload", UNSET)

        ip_address = d.pop("ipAddress", UNSET)

        user_agent = d.pop("userAgent", UNSET)

        post_system_audit_events_body = cls(
            event_type=event_type,
            ecosystem_id=ecosystem_id,
            developer_id=developer_id,
            actor_user_id=actor_user_id,
            payload=payload,
            ip_address=ip_address,
            user_agent=user_agent,
        )

        return post_system_audit_events_body
