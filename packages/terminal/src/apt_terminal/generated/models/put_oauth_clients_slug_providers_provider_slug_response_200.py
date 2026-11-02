from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PutOauthClientsSlugProvidersProviderSlugResponse200")


@_attrs_define
class PutOauthClientsSlugProvidersProviderSlugResponse200:
    """
    Attributes:
        client_slug (str):
        provider_slug (str):
        has_overrides (bool):
    """

    client_slug: str
    provider_slug: str
    has_overrides: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        client_slug = self.client_slug

        provider_slug = self.provider_slug

        has_overrides = self.has_overrides

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "clientSlug": client_slug,
                "providerSlug": provider_slug,
                "hasOverrides": has_overrides,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        client_slug = d.pop("clientSlug")

        provider_slug = d.pop("providerSlug")

        has_overrides = d.pop("hasOverrides")

        put_oauth_clients_slug_providers_provider_slug_response_200 = cls(
            client_slug=client_slug,
            provider_slug=provider_slug,
            has_overrides=has_overrides,
        )

        put_oauth_clients_slug_providers_provider_slug_response_200.additional_properties = d
        return put_oauth_clients_slug_providers_provider_slug_response_200

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
