from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostIntegrationsMeProvidersProviderIdRegisterInstanceBody")


@_attrs_define
class PostIntegrationsMeProvidersProviderIdRegisterInstanceBody:
    """
    Attributes:
        instance_url (str):
        redirect_uri (str):
        service_type (str | Unset):
    """

    instance_url: str
    redirect_uri: str
    service_type: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        instance_url = self.instance_url

        redirect_uri = self.redirect_uri

        service_type = self.service_type

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "instanceUrl": instance_url,
                "redirectUri": redirect_uri,
            }
        )
        if service_type is not UNSET:
            field_dict["serviceType"] = service_type

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        instance_url = d.pop("instanceUrl")

        redirect_uri = d.pop("redirectUri")

        service_type = d.pop("serviceType", UNSET)

        post_integrations_me_providers_provider_id_register_instance_body = cls(
            instance_url=instance_url,
            redirect_uri=redirect_uri,
            service_type=service_type,
        )

        return post_integrations_me_providers_provider_id_register_instance_body
