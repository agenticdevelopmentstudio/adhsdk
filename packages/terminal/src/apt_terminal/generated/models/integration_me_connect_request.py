from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="IntegrationMeConnectRequest")


@_attrs_define
class IntegrationMeConnectRequest:
    """Same variants as IntegrationConnectRequest (matched on `type`), minus `ecosystemId`. `providerConfigId` is refused
    with 400.

        Attributes:
            type_ (str): oauth | oauth_instance | api_key | app_password
            provider_id (str):
            service_type (str):
    """

    type_: str
    provider_id: str
    service_type: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        type_ = self.type_

        provider_id = self.provider_id

        service_type = self.service_type

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "type": type_,
                "providerId": provider_id,
                "serviceType": service_type,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        type_ = d.pop("type")

        provider_id = d.pop("providerId")

        service_type = d.pop("serviceType")

        integration_me_connect_request = cls(
            type_=type_,
            provider_id=provider_id,
            service_type=service_type,
        )

        integration_me_connect_request.additional_properties = d
        return integration_me_connect_request

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
