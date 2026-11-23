from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="SupportAccessRow")


@_attrs_define
class SupportAccessRow:
    """
    Attributes:
        id (UUID):
        grant_id (UUID):
        actor_id (str):
        method (str):
        path (str):
        route (None | str):
        request_id (None | str):
        at (datetime.datetime):
    """

    id: UUID
    grant_id: UUID
    actor_id: str
    method: str
    path: str
    route: None | str
    request_id: None | str
    at: datetime.datetime
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        grant_id = str(self.grant_id)

        actor_id = self.actor_id

        method = self.method

        path = self.path

        route: None | str
        route = self.route

        request_id: None | str
        request_id = self.request_id

        at = self.at.isoformat()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "grant_id": grant_id,
                "actor_id": actor_id,
                "method": method,
                "path": path,
                "route": route,
                "request_id": request_id,
                "at": at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        grant_id = UUID(d.pop("grant_id"))

        actor_id = d.pop("actor_id")

        method = d.pop("method")

        path = d.pop("path")

        def _parse_route(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        route = _parse_route(d.pop("route"))

        def _parse_request_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        request_id = _parse_request_id(d.pop("request_id"))

        at = datetime.datetime.fromisoformat(d.pop("at"))

        support_access_row = cls(
            id=id,
            grant_id=grant_id,
            actor_id=actor_id,
            method=method,
            path=path,
            route=route,
            request_id=request_id,
            at=at,
        )

        support_access_row.additional_properties = d
        return support_access_row

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
