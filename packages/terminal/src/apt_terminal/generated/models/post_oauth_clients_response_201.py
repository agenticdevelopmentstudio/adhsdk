from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_oauth_clients_response_201_client import PostOauthClientsResponse201Client


T = TypeVar("T", bound="PostOauthClientsResponse201")


@_attrs_define
class PostOauthClientsResponse201:
    """
    Attributes:
        client (PostOauthClientsResponse201Client):
        app_token (str | Unset):
    """

    client: PostOauthClientsResponse201Client
    app_token: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        client = self.client.to_dict()

        app_token = self.app_token

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "client": client,
            }
        )
        if app_token is not UNSET:
            field_dict["appToken"] = app_token

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_oauth_clients_response_201_client import (
            PostOauthClientsResponse201Client,
        )

        d = dict(src_dict)
        client = PostOauthClientsResponse201Client.from_dict(d.pop("client"))

        app_token = d.pop("appToken", UNSET)

        post_oauth_clients_response_201 = cls(
            client=client,
            app_token=app_token,
        )

        post_oauth_clients_response_201.additional_properties = d
        return post_oauth_clients_response_201

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
