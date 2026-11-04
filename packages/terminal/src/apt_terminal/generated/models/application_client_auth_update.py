from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.client_auth_registration_input import ClientAuthRegistrationInput


T = TypeVar("T", bound="ApplicationClientAuthUpdate")


@_attrs_define
class ApplicationClientAuthUpdate:
    """`registration: null` removes the application registration.

    Attributes:
        registration (ClientAuthRegistrationInput | None):
    """

    registration: ClientAuthRegistrationInput | None
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.client_auth_registration_input import (
            ClientAuthRegistrationInput,
        )

        registration: dict[str, Any] | None
        if isinstance(self.registration, ClientAuthRegistrationInput):
            registration = self.registration.to_dict()
        else:
            registration = self.registration

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "registration": registration,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.client_auth_registration_input import (
            ClientAuthRegistrationInput,
        )

        d = dict(src_dict)

        def _parse_registration(data: object) -> ClientAuthRegistrationInput | None:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                registration_type_0 = ClientAuthRegistrationInput.from_dict(data)

                return registration_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(ClientAuthRegistrationInput | None, data)

        registration = _parse_registration(d.pop("registration"))

        application_client_auth_update = cls(
            registration=registration,
        )

        application_client_auth_update.additional_properties = d
        return application_client_auth_update

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
