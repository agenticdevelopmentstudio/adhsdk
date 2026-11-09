from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_v1_account_mfa_response_200_preferred_method_type_1 import (
    GetV1AccountMfaResponse200PreferredMethodType1,
)
from ..models.get_v1_account_mfa_response_200_preferred_method_type_2_type_1 import (
    GetV1AccountMfaResponse200PreferredMethodType2Type1,
)
from ..models.get_v1_account_mfa_response_200_preferred_method_type_3_type_1 import (
    GetV1AccountMfaResponse200PreferredMethodType3Type1,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.get_v1_account_mfa_response_200_preference import (
        GetV1AccountMfaResponse200Preference,
    )


T = TypeVar("T", bound="GetV1AccountMfaResponse200")


@_attrs_define
class GetV1AccountMfaResponse200:
    """
    Attributes:
        sms (bool):
        totp (bool):
        webauthn (bool):
        totp_pending (bool): A TOTP enrollment awaits confirmation
        recovery_remaining (int): Unused recovery codes
        preferred_method (GetV1AccountMfaResponse200PreferredMethodType1 |
            GetV1AccountMfaResponse200PreferredMethodType2Type1 | GetV1AccountMfaResponse200PreferredMethodType3Type1 |
            None):
        object_ (Literal['account.mfa'] | Unset):
        preference (GetV1AccountMfaResponse200Preference | Unset):
    """

    sms: bool
    totp: bool
    webauthn: bool
    totp_pending: bool
    recovery_remaining: int
    preferred_method: (
        GetV1AccountMfaResponse200PreferredMethodType1
        | GetV1AccountMfaResponse200PreferredMethodType2Type1
        | GetV1AccountMfaResponse200PreferredMethodType3Type1
        | None
    )
    object_: Literal["account.mfa"] | Unset = UNSET
    preference: GetV1AccountMfaResponse200Preference | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        sms = self.sms

        totp = self.totp

        webauthn = self.webauthn

        totp_pending = self.totp_pending

        recovery_remaining = self.recovery_remaining

        preferred_method: None | str
        if (
            isinstance(self.preferred_method, GetV1AccountMfaResponse200PreferredMethodType1)
            or isinstance(
                self.preferred_method, GetV1AccountMfaResponse200PreferredMethodType2Type1
            )
            or isinstance(
                self.preferred_method, GetV1AccountMfaResponse200PreferredMethodType3Type1
            )
        ):
            preferred_method = self.preferred_method.value
        else:
            preferred_method = self.preferred_method

        object_ = self.object_

        preference: dict[str, Any] | Unset = UNSET
        if not isinstance(self.preference, Unset):
            preference = self.preference.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "sms": sms,
                "totp": totp,
                "webauthn": webauthn,
                "totp_pending": totp_pending,
                "recovery_remaining": recovery_remaining,
                "preferred_method": preferred_method,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_
        if preference is not UNSET:
            field_dict["preference"] = preference

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_v1_account_mfa_response_200_preference import (
            GetV1AccountMfaResponse200Preference,
        )

        d = dict(src_dict)
        sms = d.pop("sms")

        totp = d.pop("totp")

        webauthn = d.pop("webauthn")

        totp_pending = d.pop("totp_pending")

        recovery_remaining = d.pop("recovery_remaining")

        def _parse_preferred_method(
            data: object,
        ) -> (
            GetV1AccountMfaResponse200PreferredMethodType1
            | GetV1AccountMfaResponse200PreferredMethodType2Type1
            | GetV1AccountMfaResponse200PreferredMethodType3Type1
            | None
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                preferred_method_type_1 = GetV1AccountMfaResponse200PreferredMethodType1(data)

                return preferred_method_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                preferred_method_type_2_type_1 = (
                    GetV1AccountMfaResponse200PreferredMethodType2Type1(data)
                )

                return preferred_method_type_2_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                preferred_method_type_3_type_1 = (
                    GetV1AccountMfaResponse200PreferredMethodType3Type1(data)
                )

                return preferred_method_type_3_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                GetV1AccountMfaResponse200PreferredMethodType1
                | GetV1AccountMfaResponse200PreferredMethodType2Type1
                | GetV1AccountMfaResponse200PreferredMethodType3Type1
                | None,
                data,
            )

        preferred_method = _parse_preferred_method(d.pop("preferred_method"))

        object_ = cast(Literal["account.mfa"] | Unset, d.pop("object", UNSET))
        if object_ != "account.mfa" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'account.mfa', got '{object_}'")

        _preference = d.pop("preference", UNSET)
        preference: GetV1AccountMfaResponse200Preference | Unset
        if isinstance(_preference, Unset):
            preference = UNSET
        else:
            preference = GetV1AccountMfaResponse200Preference.from_dict(_preference)

        get_v1_account_mfa_response_200 = cls(
            sms=sms,
            totp=totp,
            webauthn=webauthn,
            totp_pending=totp_pending,
            recovery_remaining=recovery_remaining,
            preferred_method=preferred_method,
            object_=object_,
            preference=preference,
        )

        get_v1_account_mfa_response_200.additional_properties = d
        return get_v1_account_mfa_response_200

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
