from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.client_auth_provider import ClientAuthProvider
    from ..models.client_auth_registration import ClientAuthRegistration
    from ..models.ecosystem_auth_settings import EcosystemAuthSettings


T = TypeVar("T", bound="EcosystemClientAuth")


@_attrs_define
class EcosystemClientAuth:
    """An ecosystem's client auth: its policy, its own login registration, the providers.

    Attributes:
        settings (EcosystemAuthSettings): An ecosystem's sign-up and sign-in policy. Defaults are returned when nothing
            has been set.
        registration (ClientAuthRegistration | None):
        providers (list[ClientAuthProvider]):
    """

    settings: EcosystemAuthSettings
    registration: ClientAuthRegistration | None
    providers: list[ClientAuthProvider]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.client_auth_registration import ClientAuthRegistration

        settings = self.settings.to_dict()

        registration: dict[str, Any] | None
        if isinstance(self.registration, ClientAuthRegistration):
            registration = self.registration.to_dict()
        else:
            registration = self.registration

        providers = []
        for providers_item_data in self.providers:
            providers_item = providers_item_data.to_dict()
            providers.append(providers_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "settings": settings,
                "registration": registration,
                "providers": providers,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.client_auth_provider import ClientAuthProvider
        from ..models.client_auth_registration import ClientAuthRegistration
        from ..models.ecosystem_auth_settings import EcosystemAuthSettings

        d = dict(src_dict)
        settings = EcosystemAuthSettings.from_dict(d.pop("settings"))

        def _parse_registration(data: object) -> ClientAuthRegistration | None:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                registration_type_0 = ClientAuthRegistration.from_dict(data)

                return registration_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(ClientAuthRegistration | None, data)

        registration = _parse_registration(d.pop("registration"))

        providers = []
        _providers = d.pop("providers")
        for providers_item_data in _providers:
            providers_item = ClientAuthProvider.from_dict(providers_item_data)

            providers.append(providers_item)

        ecosystem_client_auth = cls(
            settings=settings,
            registration=registration,
            providers=providers,
        )

        ecosystem_client_auth.additional_properties = d
        return ecosystem_client_auth

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
