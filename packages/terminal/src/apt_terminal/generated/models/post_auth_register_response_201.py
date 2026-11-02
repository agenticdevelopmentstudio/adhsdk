from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.user import User


T = TypeVar("T", bound="PostAuthRegisterResponse201")


@_attrs_define
class PostAuthRegisterResponse201:
    """
    Attributes:
        token (str): JWT access token (Bearer credential)
        refresh_token (str): Opaque refresh token (rotated on use)
        user (User):
        email_verification_required (bool):
        email_in_use (bool | Unset):
    """

    token: str
    refresh_token: str
    user: User
    email_verification_required: bool
    email_in_use: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        token = self.token

        refresh_token = self.refresh_token

        user = self.user.to_dict()

        email_verification_required = self.email_verification_required

        email_in_use = self.email_in_use

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "token": token,
                "refreshToken": refresh_token,
                "user": user,
                "emailVerificationRequired": email_verification_required,
            }
        )
        if email_in_use is not UNSET:
            field_dict["emailInUse"] = email_in_use

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.user import User

        d = dict(src_dict)
        token = d.pop("token")

        refresh_token = d.pop("refreshToken")

        user = User.from_dict(d.pop("user"))

        email_verification_required = d.pop("emailVerificationRequired")

        email_in_use = d.pop("emailInUse", UNSET)

        post_auth_register_response_201 = cls(
            token=token,
            refresh_token=refresh_token,
            user=user,
            email_verification_required=email_verification_required,
            email_in_use=email_in_use,
        )

        post_auth_register_response_201.additional_properties = d
        return post_auth_register_response_201

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
