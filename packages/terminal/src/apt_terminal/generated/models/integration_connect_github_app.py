from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.integration_connect_github_app_type import IntegrationConnectGithubAppType

T = TypeVar("T", bound="IntegrationConnectGithubApp")


@_attrs_define
class IntegrationConnectGithubApp:
    """
    Attributes:
        type_ (IntegrationConnectGithubAppType):
        provider_id (str):
        service_type (str):
        ecosystem_id (str): Target ecosystem id (the caller must manage it)
        installation_id (str): The numeric installation id the provider redirects back with
        state (str): The HMAC-signed state returned by the install-url endpoint (CSRF)
    """

    type_: IntegrationConnectGithubAppType
    provider_id: str
    service_type: str
    ecosystem_id: str
    installation_id: str
    state: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        type_ = self.type_.value

        provider_id = self.provider_id

        service_type = self.service_type

        ecosystem_id = self.ecosystem_id

        installation_id = self.installation_id

        state = self.state

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "type": type_,
                "providerId": provider_id,
                "serviceType": service_type,
                "ecosystemId": ecosystem_id,
                "installationId": installation_id,
                "state": state,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        type_ = IntegrationConnectGithubAppType(d.pop("type"))

        provider_id = d.pop("providerId")

        service_type = d.pop("serviceType")

        ecosystem_id = d.pop("ecosystemId")

        installation_id = d.pop("installationId")

        state = d.pop("state")

        integration_connect_github_app = cls(
            type_=type_,
            provider_id=provider_id,
            service_type=service_type,
            ecosystem_id=ecosystem_id,
            installation_id=installation_id,
            state=state,
        )

        integration_connect_github_app.additional_properties = d
        return integration_connect_github_app

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
