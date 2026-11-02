from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutUsageUsageEventsIdBody")


@_attrs_define
class PutUsageUsageEventsIdBody:
    """
    Attributes:
        scope (str | Unset):
        principal_id (str | Unset):
        ecosystem_id (None | str | Unset):
        route (str | Unset):
        method (str | Unset):
        status (int | Unset):
        request_bytes (int | Unset):
        response_bytes (int | Unset):
        occurred_at (str | Unset):
    """

    scope: str | Unset = UNSET
    principal_id: str | Unset = UNSET
    ecosystem_id: None | str | Unset = UNSET
    route: str | Unset = UNSET
    method: str | Unset = UNSET
    status: int | Unset = UNSET
    request_bytes: int | Unset = UNSET
    response_bytes: int | Unset = UNSET
    occurred_at: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        scope = self.scope

        principal_id = self.principal_id

        ecosystem_id: None | str | Unset
        if isinstance(self.ecosystem_id, Unset):
            ecosystem_id = UNSET
        else:
            ecosystem_id = self.ecosystem_id

        route = self.route

        method = self.method

        status = self.status

        request_bytes = self.request_bytes

        response_bytes = self.response_bytes

        occurred_at = self.occurred_at

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if scope is not UNSET:
            field_dict["scope"] = scope
        if principal_id is not UNSET:
            field_dict["principalId"] = principal_id
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if route is not UNSET:
            field_dict["route"] = route
        if method is not UNSET:
            field_dict["method"] = method
        if status is not UNSET:
            field_dict["status"] = status
        if request_bytes is not UNSET:
            field_dict["requestBytes"] = request_bytes
        if response_bytes is not UNSET:
            field_dict["responseBytes"] = response_bytes
        if occurred_at is not UNSET:
            field_dict["occurredAt"] = occurred_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        scope = d.pop("scope", UNSET)

        principal_id = d.pop("principalId", UNSET)

        def _parse_ecosystem_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        ecosystem_id = _parse_ecosystem_id(d.pop("ecosystemId", UNSET))

        route = d.pop("route", UNSET)

        method = d.pop("method", UNSET)

        status = d.pop("status", UNSET)

        request_bytes = d.pop("requestBytes", UNSET)

        response_bytes = d.pop("responseBytes", UNSET)

        occurred_at = d.pop("occurredAt", UNSET)

        put_usage_usage_events_id_body = cls(
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

        return put_usage_usage_events_id_body
