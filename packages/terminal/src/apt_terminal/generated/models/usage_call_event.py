from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="UsageCallEvent")


@_attrs_define
class UsageCallEvent:
    """
    Attributes:
        id (int):
        scope (str):
        principal_id (str):
        route (str):
        method (str):
        status (int):
        occurred_at (str):
        kind (str):
        ecosystem_id (None | str | Unset):
        request_bytes (int | Unset):
        response_bytes (int | Unset):
        call_id (None | Unset | UUID):
        parent_call_id (None | Unset | UUID):
        route_pattern (None | str | Unset):
        duration_ms (int | None | Unset):
        db_ms (int | None | Unset):
        db_queries (int | None | Unset):
        stream_events (int | None | Unset):
    """

    id: int
    scope: str
    principal_id: str
    route: str
    method: str
    status: int
    occurred_at: str
    kind: str
    ecosystem_id: None | str | Unset = UNSET
    request_bytes: int | Unset = UNSET
    response_bytes: int | Unset = UNSET
    call_id: None | Unset | UUID = UNSET
    parent_call_id: None | Unset | UUID = UNSET
    route_pattern: None | str | Unset = UNSET
    duration_ms: int | None | Unset = UNSET
    db_ms: int | None | Unset = UNSET
    db_queries: int | None | Unset = UNSET
    stream_events: int | None | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        scope = self.scope

        principal_id = self.principal_id

        route = self.route

        method = self.method

        status = self.status

        occurred_at = self.occurred_at

        kind = self.kind

        ecosystem_id: None | str | Unset
        if isinstance(self.ecosystem_id, Unset):
            ecosystem_id = UNSET
        else:
            ecosystem_id = self.ecosystem_id

        request_bytes = self.request_bytes

        response_bytes = self.response_bytes

        call_id: None | str | Unset
        if isinstance(self.call_id, Unset):
            call_id = UNSET
        elif isinstance(self.call_id, UUID):
            call_id = str(self.call_id)
        else:
            call_id = self.call_id

        parent_call_id: None | str | Unset
        if isinstance(self.parent_call_id, Unset):
            parent_call_id = UNSET
        elif isinstance(self.parent_call_id, UUID):
            parent_call_id = str(self.parent_call_id)
        else:
            parent_call_id = self.parent_call_id

        route_pattern: None | str | Unset
        if isinstance(self.route_pattern, Unset):
            route_pattern = UNSET
        else:
            route_pattern = self.route_pattern

        duration_ms: int | None | Unset
        if isinstance(self.duration_ms, Unset):
            duration_ms = UNSET
        else:
            duration_ms = self.duration_ms

        db_ms: int | None | Unset
        if isinstance(self.db_ms, Unset):
            db_ms = UNSET
        else:
            db_ms = self.db_ms

        db_queries: int | None | Unset
        if isinstance(self.db_queries, Unset):
            db_queries = UNSET
        else:
            db_queries = self.db_queries

        stream_events: int | None | Unset
        if isinstance(self.stream_events, Unset):
            stream_events = UNSET
        else:
            stream_events = self.stream_events

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "scope": scope,
                "principal_id": principal_id,
                "route": route,
                "method": method,
                "status": status,
                "occurred_at": occurred_at,
                "kind": kind,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if request_bytes is not UNSET:
            field_dict["request_bytes"] = request_bytes
        if response_bytes is not UNSET:
            field_dict["response_bytes"] = response_bytes
        if call_id is not UNSET:
            field_dict["call_id"] = call_id
        if parent_call_id is not UNSET:
            field_dict["parent_call_id"] = parent_call_id
        if route_pattern is not UNSET:
            field_dict["route_pattern"] = route_pattern
        if duration_ms is not UNSET:
            field_dict["duration_ms"] = duration_ms
        if db_ms is not UNSET:
            field_dict["db_ms"] = db_ms
        if db_queries is not UNSET:
            field_dict["db_queries"] = db_queries
        if stream_events is not UNSET:
            field_dict["stream_events"] = stream_events

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        scope = d.pop("scope")

        principal_id = d.pop("principal_id")

        route = d.pop("route")

        method = d.pop("method")

        status = d.pop("status")

        occurred_at = d.pop("occurred_at")

        kind = d.pop("kind")

        def _parse_ecosystem_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        ecosystem_id = _parse_ecosystem_id(d.pop("ecosystem_id", UNSET))

        request_bytes = d.pop("request_bytes", UNSET)

        response_bytes = d.pop("response_bytes", UNSET)

        def _parse_call_id(data: object) -> None | Unset | UUID:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                call_id_type_0 = UUID(data)

                return call_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | Unset | UUID, data)

        call_id = _parse_call_id(d.pop("call_id", UNSET))

        def _parse_parent_call_id(data: object) -> None | Unset | UUID:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                parent_call_id_type_0 = UUID(data)

                return parent_call_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | Unset | UUID, data)

        parent_call_id = _parse_parent_call_id(d.pop("parent_call_id", UNSET))

        def _parse_route_pattern(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        route_pattern = _parse_route_pattern(d.pop("route_pattern", UNSET))

        def _parse_duration_ms(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        duration_ms = _parse_duration_ms(d.pop("duration_ms", UNSET))

        def _parse_db_ms(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        db_ms = _parse_db_ms(d.pop("db_ms", UNSET))

        def _parse_db_queries(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        db_queries = _parse_db_queries(d.pop("db_queries", UNSET))

        def _parse_stream_events(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        stream_events = _parse_stream_events(d.pop("stream_events", UNSET))

        usage_call_event = cls(
            id=id,
            scope=scope,
            principal_id=principal_id,
            route=route,
            method=method,
            status=status,
            occurred_at=occurred_at,
            kind=kind,
            ecosystem_id=ecosystem_id,
            request_bytes=request_bytes,
            response_bytes=response_bytes,
            call_id=call_id,
            parent_call_id=parent_call_id,
            route_pattern=route_pattern,
            duration_ms=duration_ms,
            db_ms=db_ms,
            db_queries=db_queries,
            stream_events=stream_events,
        )

        usage_call_event.additional_properties = d
        return usage_call_event

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
