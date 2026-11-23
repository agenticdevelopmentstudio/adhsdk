from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1SystemSupportAccessResponse200DataItem")


@_attrs_define
class GetV1SystemSupportAccessResponse200DataItem:
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
        object_ (Literal['system.support_access'] | Unset):
    """

    id: UUID
    grant_id: UUID
    actor_id: str
    method: str
    path: str
    route: None | str
    request_id: None | str
    at: datetime.datetime
    object_: Literal["system.support_access"] | Unset = UNSET
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

        object_ = self.object_

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
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["system.support_access"] | Unset, d.pop("object", UNSET))
        if object_ != "system.support_access" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'system.support_access', got '{object_}'")

        get_v1_system_support_access_response_200_data_item = cls(
            id=id,
            grant_id=grant_id,
            actor_id=actor_id,
            method=method,
            path=path,
            route=route,
            request_id=request_id,
            at=at,
            object_=object_,
        )

        get_v1_system_support_access_response_200_data_item.additional_properties = d
        return get_v1_system_support_access_response_200_data_item

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
