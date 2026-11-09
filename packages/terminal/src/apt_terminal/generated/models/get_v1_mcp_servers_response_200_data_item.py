from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1McpServersResponse200DataItem")


@_attrs_define
class GetV1McpServersResponse200DataItem:
    """
    Attributes:
        id (str):
        slug (str): The `<server>` segment in `mcp.<server>.<tool>`
        name (str):
        url (str): The remote MCP server's http(s) endpoint URL
        enabled (bool): Opt-in: a server contributes no tools until an operator enables it
        has_auth_secret (bool): true iff a per-server bearer secret is stored; the secret itself is NEVER returned
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        created_by (None | str | Unset): The admin who registered it (null for system rows)
        object_ (Literal['mcp_server'] | Unset):
    """

    id: str
    slug: str
    name: str
    url: str
    enabled: bool
    has_auth_secret: bool
    created: int
    updated: int
    created_by: None | str | Unset = UNSET
    object_: Literal["mcp_server"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        slug = self.slug

        name = self.name

        url = self.url

        enabled = self.enabled

        has_auth_secret = self.has_auth_secret

        created = self.created

        updated = self.updated

        created_by: None | str | Unset
        if isinstance(self.created_by, Unset):
            created_by = UNSET
        else:
            created_by = self.created_by

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "name": name,
                "url": url,
                "enabled": enabled,
                "has_auth_secret": has_auth_secret,
                "created": created,
                "updated": updated,
            }
        )
        if created_by is not UNSET:
            field_dict["created_by"] = created_by
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        slug = d.pop("slug")

        name = d.pop("name")

        url = d.pop("url")

        enabled = d.pop("enabled")

        has_auth_secret = d.pop("has_auth_secret")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_created_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        created_by = _parse_created_by(d.pop("created_by", UNSET))

        object_ = cast(Literal["mcp_server"] | Unset, d.pop("object", UNSET))
        if object_ != "mcp_server" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'mcp_server', got '{object_}'")

        get_v1_mcp_servers_response_200_data_item = cls(
            id=id,
            slug=slug,
            name=name,
            url=url,
            enabled=enabled,
            has_auth_secret=has_auth_secret,
            created=created,
            updated=updated,
            created_by=created_by,
            object_=object_,
        )

        get_v1_mcp_servers_response_200_data_item.additional_properties = d
        return get_v1_mcp_servers_response_200_data_item

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
