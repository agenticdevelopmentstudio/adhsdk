from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="GetIntegrationsMeConnectionsIdMediaMediaItemIdContentResponse200")


@_attrs_define
class GetIntegrationsMeConnectionsIdMediaMediaItemIdContentResponse200:
    """
    Attributes:
        url (str):
        expires_at (str):
    """

    url: str
    expires_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        url = self.url

        expires_at = self.expires_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "url": url,
                "expiresAt": expires_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        url = d.pop("url")

        expires_at = d.pop("expiresAt")

        get_integrations_me_connections_id_media_media_item_id_content_response_200 = cls(
            url=url,
            expires_at=expires_at,
        )

        get_integrations_me_connections_id_media_media_item_id_content_response_200.additional_properties = d
        return get_integrations_me_connections_id_media_media_item_id_content_response_200

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
