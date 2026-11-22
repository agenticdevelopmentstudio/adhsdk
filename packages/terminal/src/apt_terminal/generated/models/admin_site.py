from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="AdminSite")


@_attrs_define
class AdminSite:
    """
    Attributes:
        id (UUID):
        host (str): The lower-case host the site answers on.
        application_id (UUID): The product's staff `admin-site` application.
        client_id (str): That application's login registration.
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
    """

    id: UUID
    host: str
    application_id: UUID
    client_id: str
    created: int
    updated: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        host = self.host

        application_id = str(self.application_id)

        client_id = self.client_id

        created = self.created

        updated = self.updated

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "host": host,
                "application_id": application_id,
                "client_id": client_id,
                "created": created,
                "updated": updated,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        host = d.pop("host")

        application_id = UUID(d.pop("application_id"))

        client_id = d.pop("client_id")

        created = d.pop("created")

        updated = d.pop("updated")

        admin_site = cls(
            id=id,
            host=host,
            application_id=application_id,
            client_id=client_id,
            created=created,
            updated=updated,
        )

        admin_site.additional_properties = d
        return admin_site

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
