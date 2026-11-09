from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.integration_connect_app_password_type import IntegrationConnectAppPasswordType
from ..types import UNSET, Unset

T = TypeVar("T", bound="IntegrationConnectAppPassword")


@_attrs_define
class IntegrationConnectAppPassword:
    """
    Attributes:
        type_ (IntegrationConnectAppPasswordType):
        provider_id (str):
        service_type (str):
        ecosystem_id (str): Target ecosystem id (the caller must manage it)
        identifier (str):
        password (str):
        instance_url (str | Unset):
    """

    type_: IntegrationConnectAppPasswordType
    provider_id: str
    service_type: str
    ecosystem_id: str
    identifier: str
    password: str
    instance_url: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        type_ = self.type_.value

        provider_id = self.provider_id

        service_type = self.service_type

        ecosystem_id = self.ecosystem_id

        identifier = self.identifier

        password = self.password

        instance_url = self.instance_url

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "type": type_,
                "provider_id": provider_id,
                "service_type": service_type,
                "ecosystem_id": ecosystem_id,
                "identifier": identifier,
                "password": password,
            }
        )
        if instance_url is not UNSET:
            field_dict["instance_url"] = instance_url

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        type_ = IntegrationConnectAppPasswordType(d.pop("type"))

        provider_id = d.pop("provider_id")

        service_type = d.pop("service_type")

        ecosystem_id = d.pop("ecosystem_id")

        identifier = d.pop("identifier")

        password = d.pop("password")

        instance_url = d.pop("instance_url", UNSET)

        integration_connect_app_password = cls(
            type_=type_,
            provider_id=provider_id,
            service_type=service_type,
            ecosystem_id=ecosystem_id,
            identifier=identifier,
            password=password,
            instance_url=instance_url,
        )

        integration_connect_app_password.additional_properties = d
        return integration_connect_app_password

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
