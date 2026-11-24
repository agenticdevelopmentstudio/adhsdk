from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1McpServersBody")


@_attrs_define
class PostV1McpServersBody:
    """
    Attributes:
        slug (str): The globally-unique `<server>` handle in `mcp.<server>.<tool>`
        name (str):
        url (str): The remote MCP server's http(s) endpoint URL
        auth_secret (str | Unset): Optional per-server bearer secret; stored encrypted, never returned
        enabled (bool | Unset): Opt-in; defaults to disabled (contributes no tools until enabled) Default: False.
    """

    slug: str
    name: str
    url: str
    auth_secret: str | Unset = UNSET
    enabled: bool | Unset = False
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        url = self.url

        auth_secret = self.auth_secret

        enabled = self.enabled

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "name": name,
                "url": url,
            }
        )
        if auth_secret is not UNSET:
            field_dict["auth_secret"] = auth_secret
        if enabled is not UNSET:
            field_dict["enabled"] = enabled

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        url = d.pop("url")

        auth_secret = d.pop("auth_secret", UNSET)

        enabled = d.pop("enabled", UNSET)

        post_v1_mcp_servers_body = cls(
            slug=slug,
            name=name,
            url=url,
            auth_secret=auth_secret,
            enabled=enabled,
        )

        post_v1_mcp_servers_body.additional_properties = d
        return post_v1_mcp_servers_body

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
