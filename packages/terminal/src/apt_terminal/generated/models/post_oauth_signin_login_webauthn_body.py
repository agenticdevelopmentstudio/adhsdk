from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.post_oauth_signin_login_webauthn_body_response import (
        PostOauthSigninLoginWebauthnBodyResponse,
    )


T = TypeVar("T", bound="PostOauthSigninLoginWebauthnBody")


@_attrs_define
class PostOauthSigninLoginWebauthnBody:
    """
    Attributes:
        token (str):
        response (PostOauthSigninLoginWebauthnBodyResponse): AuthenticationResponseJSON
        client_id (str):
        return_ (str):
    """

    token: str
    response: PostOauthSigninLoginWebauthnBodyResponse
    client_id: str
    return_: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        token = self.token

        response = self.response.to_dict()

        client_id = self.client_id

        return_ = self.return_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "token": token,
                "response": response,
                "clientId": client_id,
                "return": return_,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_oauth_signin_login_webauthn_body_response import (
            PostOauthSigninLoginWebauthnBodyResponse,
        )

        d = dict(src_dict)
        token = d.pop("token")

        response = PostOauthSigninLoginWebauthnBodyResponse.from_dict(d.pop("response"))

        client_id = d.pop("clientId")

        return_ = d.pop("return")

        post_oauth_signin_login_webauthn_body = cls(
            token=token,
            response=response,
            client_id=client_id,
            return_=return_,
        )

        post_oauth_signin_login_webauthn_body.additional_properties = d
        return post_oauth_signin_login_webauthn_body

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
