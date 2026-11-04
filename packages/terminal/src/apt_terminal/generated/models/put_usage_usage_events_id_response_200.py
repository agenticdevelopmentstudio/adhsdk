from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define

T = TypeVar("T", bound="PutUsageUsageEventsIdResponse200")


@_attrs_define
class PutUsageUsageEventsIdResponse200:
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
        call_id (None | UUID):
        parent_call_id (None | UUID):
        kind (str):
        route_pattern (None | str):
        duration_ms (int | None):
        db_ms (int | None):
        db_queries (int | None):
        stream_events (int | None):
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
    call_id: None | UUID
    parent_call_id: None | UUID
    kind: str
    route_pattern: None | str
    duration_ms: int | None
    db_ms: int | None
    db_queries: int | None
    stream_events: int | None

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

        call_id: None | str
        if isinstance(self.call_id, UUID):
            call_id = str(self.call_id)
        else:
            call_id = self.call_id

        parent_call_id: None | str
        if isinstance(self.parent_call_id, UUID):
            parent_call_id = str(self.parent_call_id)
        else:
            parent_call_id = self.parent_call_id

        kind = self.kind

        route_pattern: None | str
        route_pattern = self.route_pattern

        duration_ms: int | None
        duration_ms = self.duration_ms

        db_ms: int | None
        db_ms = self.db_ms

        db_queries: int | None
        db_queries = self.db_queries

        stream_events: int | None
        stream_events = self.stream_events

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
                "callId": call_id,
                "parentCallId": parent_call_id,
                "kind": kind,
                "routePattern": route_pattern,
                "durationMs": duration_ms,
                "dbMs": db_ms,
                "dbQueries": db_queries,
                "streamEvents": stream_events,
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

        def _parse_call_id(data: object) -> None | UUID:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                call_id_type_0 = UUID(data)

                return call_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | UUID, data)

        call_id = _parse_call_id(d.pop("callId"))

        def _parse_parent_call_id(data: object) -> None | UUID:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                parent_call_id_type_0 = UUID(data)

                return parent_call_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | UUID, data)

        parent_call_id = _parse_parent_call_id(d.pop("parentCallId"))

        kind = d.pop("kind")

        def _parse_route_pattern(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        route_pattern = _parse_route_pattern(d.pop("routePattern"))

        def _parse_duration_ms(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        duration_ms = _parse_duration_ms(d.pop("durationMs"))

        def _parse_db_ms(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        db_ms = _parse_db_ms(d.pop("dbMs"))

        def _parse_db_queries(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        db_queries = _parse_db_queries(d.pop("dbQueries"))

        def _parse_stream_events(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        stream_events = _parse_stream_events(d.pop("streamEvents"))

        put_usage_usage_events_id_response_200 = cls(
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
            call_id=call_id,
            parent_call_id=parent_call_id,
            kind=kind,
            route_pattern=route_pattern,
            duration_ms=duration_ms,
            db_ms=db_ms,
            db_queries=db_queries,
            stream_events=stream_events,
        )

        return put_usage_usage_events_id_response_200
