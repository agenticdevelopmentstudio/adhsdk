from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.integration_connect_api_key_type import IntegrationConnectApiKeyType

if TYPE_CHECKING:
    from ..models.integration_connect_fields import IntegrationConnectFields


T = TypeVar("T", bound="IntegrationConnectApiKey")


@_attrs_define
class IntegrationConnectApiKey:
    """
    Attributes:
        type_ (IntegrationConnectApiKeyType):
        provider_id (str):
        service_type (str):
        ecosystem_id (str): Target ecosystem id (the caller must manage it)
        fields (IntegrationConnectFields): The provider's declared config fields (configFields), keyed by field key;
            validated + split into the secret vs non-secret config against the spec.
    """

    type_: IntegrationConnectApiKeyType
    provider_id: str
    service_type: str
    ecosystem_id: str
    fields: IntegrationConnectFields
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        type_ = self.type_.value

        provider_id = self.provider_id

        service_type = self.service_type

        ecosystem_id = self.ecosystem_id

        fields = self.fields.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "type": type_,
                "provider_id": provider_id,
                "service_type": service_type,
                "ecosystem_id": ecosystem_id,
                "fields": fields,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.integration_connect_fields import IntegrationConnectFields

        d = dict(src_dict)
        type_ = IntegrationConnectApiKeyType(d.pop("type"))

        provider_id = d.pop("provider_id")

        service_type = d.pop("service_type")

        ecosystem_id = d.pop("ecosystem_id")

        fields = IntegrationConnectFields.from_dict(d.pop("fields"))

        integration_connect_api_key = cls(
            type_=type_,
            provider_id=provider_id,
            service_type=service_type,
            ecosystem_id=ecosystem_id,
            fields=fields,
        )

        integration_connect_api_key.additional_properties = d
        return integration_connect_api_key

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
