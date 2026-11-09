from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1IntegrationsProvidersResponse200DataItem")


@_attrs_define
class GetV1IntegrationsProvidersResponse200DataItem:
    """
    Attributes:
        provider_id (str):
        display_name (str):
        auth_method (str):
        service_types (list[str]):
        capabilities (list[str]): read | write | auth
        object_ (Literal['integrations.provider'] | Unset):
    """

    provider_id: str
    display_name: str
    auth_method: str
    service_types: list[str]
    capabilities: list[str]
    object_: Literal["integrations.provider"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        provider_id = self.provider_id

        display_name = self.display_name

        auth_method = self.auth_method

        service_types = self.service_types

        capabilities = self.capabilities

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "provider_id": provider_id,
                "display_name": display_name,
                "auth_method": auth_method,
                "service_types": service_types,
                "capabilities": capabilities,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        provider_id = d.pop("provider_id")

        display_name = d.pop("display_name")

        auth_method = d.pop("auth_method")

        service_types = cast(list[str], d.pop("service_types"))

        capabilities = cast(list[str], d.pop("capabilities"))

        object_ = cast(Literal["integrations.provider"] | Unset, d.pop("object", UNSET))
        if object_ != "integrations.provider" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'integrations.provider', got '{object_}'")

        get_v1_integrations_providers_response_200_data_item = cls(
            provider_id=provider_id,
            display_name=display_name,
            auth_method=auth_method,
            service_types=service_types,
            capabilities=capabilities,
            object_=object_,
        )

        get_v1_integrations_providers_response_200_data_item.additional_properties = d
        return get_v1_integrations_providers_response_200_data_item

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
