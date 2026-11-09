from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.integration_provider_auth_method import IntegrationProviderAuthMethod
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.integration_provider_config_fields_item import IntegrationProviderConfigFieldsItem
    from ..models.integration_provider_links_item import IntegrationProviderLinksItem


T = TypeVar("T", bound="IntegrationProvider")


@_attrs_define
class IntegrationProvider:
    """
    Attributes:
        provider_id (str):
        display_name (str):
        auth_method (IntegrationProviderAuthMethod):
        service_types (list[str]):
        capabilities (list[str]): read | write | auth
        default_poll_interval_ms (int): Default minimum sync interval (ms)
        subtitle (str): Short human category for the picker list + filter (e.g. Email, Social)
        description (str): What the service is and what enabling it does
        links (list[IntegrationProviderLinksItem]): Out-links for the info card (homepage / docs / "get your keys")
        testable (bool): Whether a saved config for this provider can be verified — a GitHub App, or a provider
            declaring a validation endpoint. DERIVED, not stored: it is the condition POST …/provider-
            configs/{configId}/test dispatches on, so a client can draw the Test button without keeping its own list of
            which providers have one.
        config_fields (list[IntegrationProviderConfigFieldsItem] | Unset): For api_key providers: declarative
            config/credential fields, rendered + validated identically at ecosystem and user scope (absent for OAuth-style
            providers).
    """

    provider_id: str
    display_name: str
    auth_method: IntegrationProviderAuthMethod
    service_types: list[str]
    capabilities: list[str]
    default_poll_interval_ms: int
    subtitle: str
    description: str
    links: list[IntegrationProviderLinksItem]
    testable: bool
    config_fields: list[IntegrationProviderConfigFieldsItem] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        provider_id = self.provider_id

        display_name = self.display_name

        auth_method = self.auth_method.value

        service_types = self.service_types

        capabilities = self.capabilities

        default_poll_interval_ms = self.default_poll_interval_ms

        subtitle = self.subtitle

        description = self.description

        links = []
        for links_item_data in self.links:
            links_item = links_item_data.to_dict()
            links.append(links_item)

        testable = self.testable

        config_fields: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.config_fields, Unset):
            config_fields = []
            for config_fields_item_data in self.config_fields:
                config_fields_item = config_fields_item_data.to_dict()
                config_fields.append(config_fields_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "provider_id": provider_id,
                "display_name": display_name,
                "auth_method": auth_method,
                "service_types": service_types,
                "capabilities": capabilities,
                "default_poll_interval_ms": default_poll_interval_ms,
                "subtitle": subtitle,
                "description": description,
                "links": links,
                "testable": testable,
            }
        )
        if config_fields is not UNSET:
            field_dict["config_fields"] = config_fields

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.integration_provider_config_fields_item import (
            IntegrationProviderConfigFieldsItem,
        )
        from ..models.integration_provider_links_item import (
            IntegrationProviderLinksItem,
        )

        d = dict(src_dict)
        provider_id = d.pop("provider_id")

        display_name = d.pop("display_name")

        auth_method = IntegrationProviderAuthMethod(d.pop("auth_method"))

        service_types = cast(list[str], d.pop("service_types"))

        capabilities = cast(list[str], d.pop("capabilities"))

        default_poll_interval_ms = d.pop("default_poll_interval_ms")

        subtitle = d.pop("subtitle")

        description = d.pop("description")

        links = []
        _links = d.pop("links")
        for links_item_data in _links:
            links_item = IntegrationProviderLinksItem.from_dict(links_item_data)

            links.append(links_item)

        testable = d.pop("testable")

        _config_fields = d.pop("config_fields", UNSET)
        config_fields: list[IntegrationProviderConfigFieldsItem] | Unset = UNSET
        if _config_fields is not UNSET:
            config_fields = []
            for config_fields_item_data in _config_fields:
                config_fields_item = IntegrationProviderConfigFieldsItem.from_dict(
                    config_fields_item_data
                )

                config_fields.append(config_fields_item)

        integration_provider = cls(
            provider_id=provider_id,
            display_name=display_name,
            auth_method=auth_method,
            service_types=service_types,
            capabilities=capabilities,
            default_poll_interval_ms=default_poll_interval_ms,
            subtitle=subtitle,
            description=description,
            links=links,
            testable=testable,
            config_fields=config_fields,
        )

        integration_provider.additional_properties = d
        return integration_provider

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
