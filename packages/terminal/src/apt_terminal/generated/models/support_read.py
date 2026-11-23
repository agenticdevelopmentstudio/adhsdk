from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.support_read_grantee import SupportReadGrantee


T = TypeVar("T", bound="SupportRead")


@_attrs_define
class SupportRead:
    """
    Attributes:
        id (UUID):
        grant_id (UUID):
        grantee (SupportReadGrantee):
        route (None | str): The route pattern that was read.
        path (str):
        at (datetime.datetime):
    """

    id: UUID
    grant_id: UUID
    grantee: SupportReadGrantee
    route: None | str
    path: str
    at: datetime.datetime
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        grant_id = str(self.grant_id)

        grantee = self.grantee.to_dict()

        route: None | str
        route = self.route

        path = self.path

        at = self.at.isoformat()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "grant_id": grant_id,
                "grantee": grantee,
                "route": route,
                "path": path,
                "at": at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.support_read_grantee import SupportReadGrantee

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        grant_id = UUID(d.pop("grant_id"))

        grantee = SupportReadGrantee.from_dict(d.pop("grantee"))

        def _parse_route(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        route = _parse_route(d.pop("route"))

        path = d.pop("path")

        at = datetime.datetime.fromisoformat(d.pop("at"))

        support_read = cls(
            id=id,
            grant_id=grant_id,
            grantee=grantee,
            route=route,
            path=path,
            at=at,
        )

        support_read.additional_properties = d
        return support_read

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
