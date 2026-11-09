from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1OauthClientsByIdRotateTokenResponse200")


@_attrs_define
class PostV1OauthClientsByIdRotateTokenResponse200:
    """
    Attributes:
        app_token (str):
        app_token_prefix (str):
        object_ (Literal['oauth.client'] | Unset):
    """

    app_token: str
    app_token_prefix: str
    object_: Literal["oauth.client"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        app_token = self.app_token

        app_token_prefix = self.app_token_prefix

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "app_token": app_token,
                "app_token_prefix": app_token_prefix,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        app_token = d.pop("app_token")

        app_token_prefix = d.pop("app_token_prefix")

        object_ = cast(Literal["oauth.client"] | Unset, d.pop("object", UNSET))
        if object_ != "oauth.client" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'oauth.client', got '{object_}'")

        post_v1_oauth_clients_by_id_rotate_token_response_200 = cls(
            app_token=app_token,
            app_token_prefix=app_token_prefix,
            object_=object_,
        )

        post_v1_oauth_clients_by_id_rotate_token_response_200.additional_properties = d
        return post_v1_oauth_clients_by_id_rotate_token_response_200

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
