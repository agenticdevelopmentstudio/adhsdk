from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostOauthSigninCallbackBody")


@_attrs_define
class PostOauthSigninCallbackBody:
    """
    Attributes:
        state (str):
        code (str | Unset):
        error (str | Unset):
        user (str | Unset): Apple's one-time name, as JSON
    """

    state: str
    code: str | Unset = UNSET
    error: str | Unset = UNSET
    user: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        state = self.state

        code = self.code

        error = self.error

        user = self.user

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "state": state,
            }
        )
        if code is not UNSET:
            field_dict["code"] = code
        if error is not UNSET:
            field_dict["error"] = error
        if user is not UNSET:
            field_dict["user"] = user

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        state = d.pop("state")

        code = d.pop("code", UNSET)

        error = d.pop("error", UNSET)

        user = d.pop("user", UNSET)

        post_oauth_signin_callback_body = cls(
            state=state,
            code=code,
            error=error,
            user=user,
        )

        post_oauth_signin_callback_body.additional_properties = d
        return post_oauth_signin_callback_body

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
