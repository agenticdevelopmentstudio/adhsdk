from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.ecosystem_auth_settings_signup_mode import EcosystemAuthSettingsSignupMode

T = TypeVar("T", bound="EcosystemAuthSettings")


@_attrs_define
class EcosystemAuthSettings:
    """An ecosystem's sign-up and sign-in policy. Defaults are returned when nothing has been set.

    Attributes:
        signup_mode (EcosystemAuthSettingsSignupMode): Defaults to invite_only
        login_enabled (bool): Defaults to true
        password_enabled (bool): Email and password sign-in and sign-up for the customer realm. Defaults to true
        allowed_providers (list[str] | None): null means every configured provider. An empty array is stored as null,
            never as "none".
    """

    signup_mode: EcosystemAuthSettingsSignupMode
    login_enabled: bool
    password_enabled: bool
    allowed_providers: list[str] | None
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        signup_mode = self.signup_mode.value

        login_enabled = self.login_enabled

        password_enabled = self.password_enabled

        allowed_providers: list[str] | None
        if isinstance(self.allowed_providers, list):
            allowed_providers = self.allowed_providers

        else:
            allowed_providers = self.allowed_providers

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "signupMode": signup_mode,
                "loginEnabled": login_enabled,
                "passwordEnabled": password_enabled,
                "allowedProviders": allowed_providers,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        signup_mode = EcosystemAuthSettingsSignupMode(d.pop("signupMode"))

        login_enabled = d.pop("loginEnabled")

        password_enabled = d.pop("passwordEnabled")

        def _parse_allowed_providers(data: object) -> list[str] | None:
            if data is None:
                return data
            try:
                if not isinstance(data, list):
                    raise TypeError()
                allowed_providers_type_0 = cast(list[str], data)

                return allowed_providers_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(list[str] | None, data)

        allowed_providers = _parse_allowed_providers(d.pop("allowedProviders"))

        ecosystem_auth_settings = cls(
            signup_mode=signup_mode,
            login_enabled=login_enabled,
            password_enabled=password_enabled,
            allowed_providers=allowed_providers,
        )

        ecosystem_auth_settings.additional_properties = d
        return ecosystem_auth_settings

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
