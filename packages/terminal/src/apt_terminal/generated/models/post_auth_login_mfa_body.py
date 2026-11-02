from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_auth_login_mfa_body_method import PostAuthLoginMfaBodyMethod

T = TypeVar("T", bound="PostAuthLoginMfaBody")


@_attrs_define
class PostAuthLoginMfaBody:
    """
    Attributes:
        token (str): MFA pending token
        method (PostAuthLoginMfaBodyMethod):
        code (str):
    """

    token: str
    method: PostAuthLoginMfaBodyMethod
    code: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        token = self.token

        method = self.method.value

        code = self.code

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "token": token,
                "method": method,
                "code": code,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        token = d.pop("token")

        method = PostAuthLoginMfaBodyMethod(d.pop("method"))

        code = d.pop("code")

        post_auth_login_mfa_body = cls(
            token=token,
            method=method,
            code=code,
        )

        post_auth_login_mfa_body.additional_properties = d
        return post_auth_login_mfa_body

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
