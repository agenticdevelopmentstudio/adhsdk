from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.ecosystem_auth_settings_update_signup_mode import (
    EcosystemAuthSettingsUpdateSignupMode,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="EcosystemAuthSettingsUpdate")


@_attrs_define
class EcosystemAuthSettingsUpdate:
    """A partial update — supply at least one field. Anything omitted is left as it was.

    Attributes:
        signup_mode (EcosystemAuthSettingsUpdateSignupMode | Unset):
        login_enabled (bool | Unset):
        password_enabled (bool | Unset):
        allowed_providers (list[str] | None | Unset): Every slug must name a configured provider, or the call is a 400.
            An empty array is coerced to null (all providers) rather than locking everyone out.
    """

    signup_mode: EcosystemAuthSettingsUpdateSignupMode | Unset = UNSET
    login_enabled: bool | Unset = UNSET
    password_enabled: bool | Unset = UNSET
    allowed_providers: list[str] | None | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        signup_mode: str | Unset = UNSET
        if not isinstance(self.signup_mode, Unset):
            signup_mode = self.signup_mode.value

        login_enabled = self.login_enabled

        password_enabled = self.password_enabled

        allowed_providers: list[str] | None | Unset
        if isinstance(self.allowed_providers, Unset):
            allowed_providers = UNSET
        elif isinstance(self.allowed_providers, list):
            allowed_providers = self.allowed_providers

        else:
            allowed_providers = self.allowed_providers

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if signup_mode is not UNSET:
            field_dict["signupMode"] = signup_mode
        if login_enabled is not UNSET:
            field_dict["loginEnabled"] = login_enabled
        if password_enabled is not UNSET:
            field_dict["passwordEnabled"] = password_enabled
        if allowed_providers is not UNSET:
            field_dict["allowedProviders"] = allowed_providers

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        _signup_mode = d.pop("signupMode", UNSET)
        signup_mode: EcosystemAuthSettingsUpdateSignupMode | Unset
        if isinstance(_signup_mode, Unset):
            signup_mode = UNSET
        else:
            signup_mode = EcosystemAuthSettingsUpdateSignupMode(_signup_mode)

        login_enabled = d.pop("loginEnabled", UNSET)

        password_enabled = d.pop("passwordEnabled", UNSET)

        def _parse_allowed_providers(data: object) -> list[str] | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, list):
                    raise TypeError()
                allowed_providers_type_0 = cast(list[str], data)

                return allowed_providers_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(list[str] | None | Unset, data)

        allowed_providers = _parse_allowed_providers(d.pop("allowedProviders", UNSET))

        ecosystem_auth_settings_update = cls(
            signup_mode=signup_mode,
            login_enabled=login_enabled,
            password_enabled=password_enabled,
            allowed_providers=allowed_providers,
        )

        ecosystem_auth_settings_update.additional_properties = d
        return ecosystem_auth_settings_update

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
