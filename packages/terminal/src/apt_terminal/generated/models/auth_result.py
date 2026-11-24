from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.user import User


T = TypeVar("T", bound="AuthResult")


@_attrs_define
class AuthResult:
    """
    Attributes:
        token (str): JWT access token (Bearer credential)
        refresh_token (str): Opaque refresh token (rotated on use)
        user (User):
    """

    token: str
    refresh_token: str
    user: User
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        token = self.token

        refresh_token = self.refresh_token

        user = self.user.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "token": token,
                "refresh_token": refresh_token,
                "user": user,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.user import User

        d = dict(src_dict)
        token = d.pop("token")

        refresh_token = d.pop("refresh_token")

        user = User.from_dict(d.pop("user"))

        auth_result = cls(
            token=token,
            refresh_token=refresh_token,
            user=user,
        )

        auth_result.additional_properties = d
        return auth_result

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
