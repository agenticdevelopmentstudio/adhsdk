from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_account_mfa_passkeys_registration_options_response_200_options import (
        PostV1AccountMfaPasskeysRegistrationOptionsResponse200Options,
    )


T = TypeVar("T", bound="PostV1AccountMfaPasskeysRegistrationOptionsResponse200")


@_attrs_define
class PostV1AccountMfaPasskeysRegistrationOptionsResponse200:
    """
    Attributes:
        options (PostV1AccountMfaPasskeysRegistrationOptionsResponse200Options): PublicKeyCredentialCreationOptionsJSON
        token (str): Signed registration challenge token
        object_ (Literal['account.mfa.passkeys.registration_option'] | Unset):
    """

    options: PostV1AccountMfaPasskeysRegistrationOptionsResponse200Options
    token: str
    object_: Literal["account.mfa.passkeys.registration_option"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        options = self.options.to_dict()

        token = self.token

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "options": options,
                "token": token,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_account_mfa_passkeys_registration_options_response_200_options import (
            PostV1AccountMfaPasskeysRegistrationOptionsResponse200Options,
        )

        d = dict(src_dict)
        options = PostV1AccountMfaPasskeysRegistrationOptionsResponse200Options.from_dict(
            d.pop("options")
        )

        token = d.pop("token")

        object_ = cast(
            Literal["account.mfa.passkeys.registration_option"] | Unset, d.pop("object", UNSET)
        )
        if object_ != "account.mfa.passkeys.registration_option" and not isinstance(object_, Unset):
            raise ValueError(
                f"object must match const 'account.mfa.passkeys.registration_option', got '{object_}'"
            )

        post_v1_account_mfa_passkeys_registration_options_response_200 = cls(
            options=options,
            token=token,
            object_=object_,
        )

        post_v1_account_mfa_passkeys_registration_options_response_200.additional_properties = d
        return post_v1_account_mfa_passkeys_registration_options_response_200

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
