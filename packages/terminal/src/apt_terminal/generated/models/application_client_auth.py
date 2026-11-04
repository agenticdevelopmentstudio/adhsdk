from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.application_client_auth_platform import ApplicationClientAuthPlatform

if TYPE_CHECKING:
    from ..models.client_auth_registration import ClientAuthRegistration


T = TypeVar("T", bound="ApplicationClientAuth")


@_attrs_define
class ApplicationClientAuth:
    """An application's client auth. The ecosystem's policy governs every sign-in; `registration` null means the
    application signs in through the ecosystem's registration.

        Attributes:
            platform (ApplicationClientAuthPlatform): Set on the application itself; it shapes what the registration accepts
            registration (ClientAuthRegistration | None):
    """

    platform: ApplicationClientAuthPlatform
    registration: ClientAuthRegistration | None
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.client_auth_registration import ClientAuthRegistration

        platform = self.platform.value

        registration: dict[str, Any] | None
        if isinstance(self.registration, ClientAuthRegistration):
            registration = self.registration.to_dict()
        else:
            registration = self.registration

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "platform": platform,
                "registration": registration,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.client_auth_registration import ClientAuthRegistration

        d = dict(src_dict)
        platform = ApplicationClientAuthPlatform(d.pop("platform"))

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

        application_client_auth = cls(
            platform=platform,
            registration=registration,
        )

        application_client_auth.additional_properties = d
        return application_client_auth

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
