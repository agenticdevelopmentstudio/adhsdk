from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_account_mfa_response_200_preferred_method_type_1 import (
    GetAccountMfaResponse200PreferredMethodType1,
)
from ..models.get_account_mfa_response_200_preferred_method_type_2_type_1 import (
    GetAccountMfaResponse200PreferredMethodType2Type1,
)
from ..models.get_account_mfa_response_200_preferred_method_type_3_type_1 import (
    GetAccountMfaResponse200PreferredMethodType3Type1,
)

T = TypeVar("T", bound="GetAccountMfaResponse200")


@_attrs_define
class GetAccountMfaResponse200:
    """
    Attributes:
        sms (bool):
        totp (bool):
        webauthn (bool):
        totp_pending (bool): A TOTP enrollment awaits confirmation
        recovery_remaining (int): Unused recovery codes
        preferred_method (GetAccountMfaResponse200PreferredMethodType1 |
            GetAccountMfaResponse200PreferredMethodType2Type1 | GetAccountMfaResponse200PreferredMethodType3Type1 | None):
    """

    sms: bool
    totp: bool
    webauthn: bool
    totp_pending: bool
    recovery_remaining: int
    preferred_method: (
        GetAccountMfaResponse200PreferredMethodType1
        | GetAccountMfaResponse200PreferredMethodType2Type1
        | GetAccountMfaResponse200PreferredMethodType3Type1
        | None
    )
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        sms = self.sms

        totp = self.totp

        webauthn = self.webauthn

        totp_pending = self.totp_pending

        recovery_remaining = self.recovery_remaining

        preferred_method: None | str
        if (
            isinstance(self.preferred_method, GetAccountMfaResponse200PreferredMethodType1)
            or isinstance(self.preferred_method, GetAccountMfaResponse200PreferredMethodType2Type1)
            or isinstance(self.preferred_method, GetAccountMfaResponse200PreferredMethodType3Type1)
        ):
            preferred_method = self.preferred_method.value
        else:
            preferred_method = self.preferred_method

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "sms": sms,
                "totp": totp,
                "webauthn": webauthn,
                "totpPending": totp_pending,
                "recoveryRemaining": recovery_remaining,
                "preferredMethod": preferred_method,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        sms = d.pop("sms")

        totp = d.pop("totp")

        webauthn = d.pop("webauthn")

        totp_pending = d.pop("totpPending")

        recovery_remaining = d.pop("recoveryRemaining")

        def _parse_preferred_method(
            data: object,
        ) -> (
            GetAccountMfaResponse200PreferredMethodType1
            | GetAccountMfaResponse200PreferredMethodType2Type1
            | GetAccountMfaResponse200PreferredMethodType3Type1
            | None
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                preferred_method_type_1 = GetAccountMfaResponse200PreferredMethodType1(data)

                return preferred_method_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                preferred_method_type_2_type_1 = GetAccountMfaResponse200PreferredMethodType2Type1(
                    data
                )

                return preferred_method_type_2_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, str):
                    raise TypeError()
                preferred_method_type_3_type_1 = GetAccountMfaResponse200PreferredMethodType3Type1(
                    data
                )

                return preferred_method_type_3_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                GetAccountMfaResponse200PreferredMethodType1
                | GetAccountMfaResponse200PreferredMethodType2Type1
                | GetAccountMfaResponse200PreferredMethodType3Type1
                | None,
                data,
            )

        preferred_method = _parse_preferred_method(d.pop("preferredMethod"))

        get_account_mfa_response_200 = cls(
            sms=sms,
            totp=totp,
            webauthn=webauthn,
            totp_pending=totp_pending,
            recovery_remaining=recovery_remaining,
            preferred_method=preferred_method,
        )

        get_account_mfa_response_200.additional_properties = d
        return get_account_mfa_response_200

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
