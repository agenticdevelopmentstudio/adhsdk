from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostOauthClientsSlugRotateTokenResponse200")


@_attrs_define
class PostOauthClientsSlugRotateTokenResponse200:
    """
    Attributes:
        app_token (str):
        app_token_prefix (str):
    """

    app_token: str
    app_token_prefix: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        app_token = self.app_token

        app_token_prefix = self.app_token_prefix

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "appToken": app_token,
                "appTokenPrefix": app_token_prefix,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        app_token = d.pop("appToken")

        app_token_prefix = d.pop("appTokenPrefix")

        post_oauth_clients_slug_rotate_token_response_200 = cls(
            app_token=app_token,
            app_token_prefix=app_token_prefix,
        )

        post_oauth_clients_slug_rotate_token_response_200.additional_properties = d
        return post_oauth_clients_slug_rotate_token_response_200

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
