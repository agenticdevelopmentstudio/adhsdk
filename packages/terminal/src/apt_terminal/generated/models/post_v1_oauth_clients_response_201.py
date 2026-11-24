from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_oauth_clients_response_201_client import (
        PostV1OauthClientsResponse201Client,
    )


T = TypeVar("T", bound="PostV1OauthClientsResponse201")


@_attrs_define
class PostV1OauthClientsResponse201:
    """
    Attributes:
        client (PostV1OauthClientsResponse201Client):
        object_ (Literal['oauth.client'] | Unset):
        app_token (str | Unset):
    """

    client: PostV1OauthClientsResponse201Client
    object_: Literal["oauth.client"] | Unset = UNSET
    app_token: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        client = self.client.to_dict()

        object_ = self.object_

        app_token = self.app_token

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "client": client,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_
        if app_token is not UNSET:
            field_dict["app_token"] = app_token

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_oauth_clients_response_201_client import (
            PostV1OauthClientsResponse201Client,
        )

        d = dict(src_dict)
        client = PostV1OauthClientsResponse201Client.from_dict(d.pop("client"))

        object_ = cast(Literal["oauth.client"] | Unset, d.pop("object", UNSET))
        if object_ != "oauth.client" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'oauth.client', got '{object_}'")

        app_token = d.pop("app_token", UNSET)

        post_v1_oauth_clients_response_201 = cls(
            client=client,
            object_=object_,
            app_token=app_token,
        )

        post_v1_oauth_clients_response_201.additional_properties = d
        return post_v1_oauth_clients_response_201

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
