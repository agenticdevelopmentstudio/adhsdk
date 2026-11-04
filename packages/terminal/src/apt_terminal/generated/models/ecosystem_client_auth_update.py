from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.client_auth_registration_input import ClientAuthRegistrationInput
    from ..models.ecosystem_auth_settings_update import EcosystemAuthSettingsUpdate


T = TypeVar("T", bound="EcosystemClientAuthUpdate")


@_attrs_define
class EcosystemClientAuthUpdate:
    """Supply at least one key. `registration: null` removes the ecosystem registration. A registration for the platform
    ecosystem is a 400.

        Attributes:
            settings (EcosystemAuthSettingsUpdate | Unset): A partial update — supply at least one field. Anything omitted
                is left as it was.
            registration (ClientAuthRegistrationInput | None | Unset):
    """

    settings: EcosystemAuthSettingsUpdate | Unset = UNSET
    registration: ClientAuthRegistrationInput | None | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.client_auth_registration_input import (
            ClientAuthRegistrationInput,
        )

        settings: dict[str, Any] | Unset = UNSET
        if not isinstance(self.settings, Unset):
            settings = self.settings.to_dict()

        registration: dict[str, Any] | None | Unset
        if isinstance(self.registration, Unset):
            registration = UNSET
        elif isinstance(self.registration, ClientAuthRegistrationInput):
            registration = self.registration.to_dict()
        else:
            registration = self.registration

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if settings is not UNSET:
            field_dict["settings"] = settings
        if registration is not UNSET:
            field_dict["registration"] = registration

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.client_auth_registration_input import (
            ClientAuthRegistrationInput,
        )
        from ..models.ecosystem_auth_settings_update import (
            EcosystemAuthSettingsUpdate,
        )

        d = dict(src_dict)
        _settings = d.pop("settings", UNSET)
        settings: EcosystemAuthSettingsUpdate | Unset
        if isinstance(_settings, Unset):
            settings = UNSET
        else:
            settings = EcosystemAuthSettingsUpdate.from_dict(_settings)

        def _parse_registration(data: object) -> ClientAuthRegistrationInput | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                registration_type_0 = ClientAuthRegistrationInput.from_dict(data)

                return registration_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(ClientAuthRegistrationInput | None | Unset, data)

        registration = _parse_registration(d.pop("registration", UNSET))

        ecosystem_client_auth_update = cls(
            settings=settings,
            registration=registration,
        )

        ecosystem_client_auth_update.additional_properties = d
        return ecosystem_client_auth_update

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
