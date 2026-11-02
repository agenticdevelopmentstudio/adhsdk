from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetSystemAuditEventsResponse200Item")


@_attrs_define
class GetSystemAuditEventsResponse200Item:
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
        created_at (str):
    """

    id: str
    ecosystem_id: None | str
    developer_id: None | str
    actor_user_id: None | str
    event_type: str
    payload: str
    ip_address: str
    user_agent: str
    created_at: str

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

        created_at = self.created_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "developerId": developer_id,
                "actorUserId": actor_user_id,
                "eventType": event_type,
                "payload": payload,
                "ipAddress": ip_address,
                "userAgent": user_agent,
                "createdAt": created_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        def _parse_ecosystem_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        ecosystem_id = _parse_ecosystem_id(d.pop("ecosystemId"))

        def _parse_developer_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        developer_id = _parse_developer_id(d.pop("developerId"))

        def _parse_actor_user_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        actor_user_id = _parse_actor_user_id(d.pop("actorUserId"))

        event_type = d.pop("eventType")

        payload = d.pop("payload")

        ip_address = d.pop("ipAddress")

        user_agent = d.pop("userAgent")

        created_at = d.pop("createdAt")

        get_system_audit_events_response_200_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            developer_id=developer_id,
            actor_user_id=actor_user_id,
            event_type=event_type,
            payload=payload,
            ip_address=ip_address,
            user_agent=user_agent,
            created_at=created_at,
        )

        return get_system_audit_events_response_200_item
