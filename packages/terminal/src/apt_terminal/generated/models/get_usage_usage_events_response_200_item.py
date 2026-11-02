from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetUsageUsageEventsResponse200Item")


@_attrs_define
class GetUsageUsageEventsResponse200Item:
    """
    Attributes:
        id (int):
        scope (str):
        principal_id (str):
        ecosystem_id (None | str):
        route (str):
        method (str):
        status (int):
        request_bytes (int):
        response_bytes (int):
        occurred_at (str):
    """

    id: int
    scope: str
    principal_id: str
    ecosystem_id: None | str
    route: str
    method: str
    status: int
    request_bytes: int
    response_bytes: int
    occurred_at: str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        scope = self.scope

        principal_id = self.principal_id

        ecosystem_id: None | str
        ecosystem_id = self.ecosystem_id

        route = self.route

        method = self.method

        status = self.status

        request_bytes = self.request_bytes

        response_bytes = self.response_bytes

        occurred_at = self.occurred_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "scope": scope,
                "principalId": principal_id,
                "ecosystemId": ecosystem_id,
                "route": route,
                "method": method,
                "status": status,
                "requestBytes": request_bytes,
                "responseBytes": response_bytes,
                "occurredAt": occurred_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        scope = d.pop("scope")

        principal_id = d.pop("principalId")

        def _parse_ecosystem_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        ecosystem_id = _parse_ecosystem_id(d.pop("ecosystemId"))

        route = d.pop("route")

        method = d.pop("method")

        status = d.pop("status")

        request_bytes = d.pop("requestBytes")

        response_bytes = d.pop("responseBytes")

        occurred_at = d.pop("occurredAt")

        get_usage_usage_events_response_200_item = cls(
            id=id,
            scope=scope,
            principal_id=principal_id,
            ecosystem_id=ecosystem_id,
            route=route,
            method=method,
            status=status,
            request_bytes=request_bytes,
            response_bytes=response_bytes,
            occurred_at=occurred_at,
        )

        return get_usage_usage_events_response_200_item
