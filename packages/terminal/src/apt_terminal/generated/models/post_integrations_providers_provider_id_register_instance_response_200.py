from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostIntegrationsProvidersProviderIdRegisterInstanceResponse200")


@_attrs_define
class PostIntegrationsProvidersProviderIdRegisterInstanceResponse200:
    """
    Attributes:
        state (str):
        authorize_url (str):
        client_id (str):
    """

    state: str
    authorize_url: str
    client_id: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        state = self.state

        authorize_url = self.authorize_url

        client_id = self.client_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "state": state,
                "authorizeUrl": authorize_url,
                "clientId": client_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        state = d.pop("state")

        authorize_url = d.pop("authorizeUrl")

        client_id = d.pop("clientId")

        post_integrations_providers_provider_id_register_instance_response_200 = cls(
            state=state,
            authorize_url=authorize_url,
            client_id=client_id,
        )

        post_integrations_providers_provider_id_register_instance_response_200.additional_properties = d
        return post_integrations_providers_provider_id_register_instance_response_200

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
