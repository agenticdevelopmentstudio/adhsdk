from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostUsageUsageEventsBody")


@_attrs_define
class PostUsageUsageEventsBody:
    """
    Attributes:
        scope (str):
        principal_id (str):
        route (str):
        method (str):
        status (int):
        request_bytes (int):
        response_bytes (int):
        occurred_at (str):
        ecosystem_id (None | str | Unset):
    """

    scope: str
    principal_id: str
    route: str
    method: str
    status: int
    request_bytes: int
    response_bytes: int
    occurred_at: str
    ecosystem_id: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        scope = self.scope

        principal_id = self.principal_id

        route = self.route

        method = self.method

        status = self.status

        request_bytes = self.request_bytes

        response_bytes = self.response_bytes

        occurred_at = self.occurred_at

        ecosystem_id: None | str | Unset
        if isinstance(self.ecosystem_id, Unset):
            ecosystem_id = UNSET
        else:
            ecosystem_id = self.ecosystem_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "scope": scope,
                "principalId": principal_id,
                "route": route,
                "method": method,
                "status": status,
                "requestBytes": request_bytes,
                "responseBytes": response_bytes,
                "occurredAt": occurred_at,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        scope = d.pop("scope")

        principal_id = d.pop("principalId")

        route = d.pop("route")

        method = d.pop("method")

        status = d.pop("status")

        request_bytes = d.pop("requestBytes")

        response_bytes = d.pop("responseBytes")

        occurred_at = d.pop("occurredAt")

        def _parse_ecosystem_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        ecosystem_id = _parse_ecosystem_id(d.pop("ecosystemId", UNSET))

        post_usage_usage_events_body = cls(
            scope=scope,
            principal_id=principal_id,
            route=route,
            method=method,
            status=status,
            request_bytes=request_bytes,
            response_bytes=response_bytes,
            occurred_at=occurred_at,
            ecosystem_id=ecosystem_id,
        )

        return post_usage_usage_events_body
