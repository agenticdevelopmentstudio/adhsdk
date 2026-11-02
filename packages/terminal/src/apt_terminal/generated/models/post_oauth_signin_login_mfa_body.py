from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_oauth_signin_login_mfa_body_method import PostOauthSigninLoginMfaBodyMethod

T = TypeVar("T", bound="PostOauthSigninLoginMfaBody")


@_attrs_define
class PostOauthSigninLoginMfaBody:
    """
    Attributes:
        token (str): MFA pending token
        method (PostOauthSigninLoginMfaBodyMethod):
        code (str):
        client_id (str):
        return_ (str):
    """

    token: str
    method: PostOauthSigninLoginMfaBodyMethod
    code: str
    client_id: str
    return_: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        token = self.token

        method = self.method.value

        code = self.code

        client_id = self.client_id

        return_ = self.return_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "token": token,
                "method": method,
                "code": code,
                "clientId": client_id,
                "return": return_,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        token = d.pop("token")

        method = PostOauthSigninLoginMfaBodyMethod(d.pop("method"))

        code = d.pop("code")

        client_id = d.pop("clientId")

        return_ = d.pop("return")

        post_oauth_signin_login_mfa_body = cls(
            token=token,
            method=method,
            code=code,
            client_id=client_id,
            return_=return_,
        )

        post_oauth_signin_login_mfa_body.additional_properties = d
        return post_oauth_signin_login_mfa_body

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
