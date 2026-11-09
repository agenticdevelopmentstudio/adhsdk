from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1UsageEventsResponse201")


@_attrs_define
class PostV1UsageEventsResponse201:
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
        object_ (Literal['usage.event'] | Unset):
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
    object_: Literal["usage.event"] | Unset = UNSET

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

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "scope": scope,
                "principal_id": principal_id,
                "ecosystem_id": ecosystem_id,
                "route": route,
                "method": method,
                "status": status,
                "request_bytes": request_bytes,
                "response_bytes": response_bytes,
                "occurred_at": occurred_at,
                "call_id": call_id,
                "parent_call_id": parent_call_id,
                "kind": kind,
                "route_pattern": route_pattern,
                "duration_ms": duration_ms,
                "db_ms": db_ms,
                "db_queries": db_queries,
                "stream_events": stream_events,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        scope = d.pop("scope")

        principal_id = d.pop("principal_id")

        def _parse_ecosystem_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        ecosystem_id = _parse_ecosystem_id(d.pop("ecosystem_id"))

        route = d.pop("route")

        method = d.pop("method")

        status = d.pop("status")

        request_bytes = d.pop("request_bytes")

        response_bytes = d.pop("response_bytes")

        occurred_at = d.pop("occurred_at")

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

        call_id = _parse_call_id(d.pop("call_id"))

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

        parent_call_id = _parse_parent_call_id(d.pop("parent_call_id"))

        kind = d.pop("kind")

        def _parse_route_pattern(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        route_pattern = _parse_route_pattern(d.pop("route_pattern"))

        def _parse_duration_ms(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        duration_ms = _parse_duration_ms(d.pop("duration_ms"))

        def _parse_db_ms(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        db_ms = _parse_db_ms(d.pop("db_ms"))

        def _parse_db_queries(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        db_queries = _parse_db_queries(d.pop("db_queries"))

        def _parse_stream_events(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        stream_events = _parse_stream_events(d.pop("stream_events"))

        object_ = cast(Literal["usage.event"] | Unset, d.pop("object", UNSET))
        if object_ != "usage.event" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'usage.event', got '{object_}'")

        post_v1_usage_events_response_201 = cls(
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
            object_=object_,
        )

        return post_v1_usage_events_response_201
