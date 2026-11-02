from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.get_oauth_clients_slug_response_200_client import (
        GetOauthClientsSlugResponse200Client,
    )
    from ..models.get_oauth_clients_slug_response_200_providers_item import (
        GetOauthClientsSlugResponse200ProvidersItem,
    )


T = TypeVar("T", bound="GetOauthClientsSlugResponse200")


@_attrs_define
class GetOauthClientsSlugResponse200:
    """
    Attributes:
        client (GetOauthClientsSlugResponse200Client):
        providers (list[GetOauthClientsSlugResponse200ProvidersItem]):
    """

    client: GetOauthClientsSlugResponse200Client
    providers: list[GetOauthClientsSlugResponse200ProvidersItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        client = self.client.to_dict()

        providers = []
        for providers_item_data in self.providers:
            providers_item = providers_item_data.to_dict()
            providers.append(providers_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "client": client,
                "providers": providers,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_oauth_clients_slug_response_200_client import (
            GetOauthClientsSlugResponse200Client,
        )
        from ..models.get_oauth_clients_slug_response_200_providers_item import (
            GetOauthClientsSlugResponse200ProvidersItem,
        )

        d = dict(src_dict)
        client = GetOauthClientsSlugResponse200Client.from_dict(d.pop("client"))

        providers = []
        _providers = d.pop("providers")
        for providers_item_data in _providers:
            providers_item = GetOauthClientsSlugResponse200ProvidersItem.from_dict(
                providers_item_data
            )

            providers.append(providers_item)

        get_oauth_clients_slug_response_200 = cls(
            client=client,
            providers=providers,
        )

        get_oauth_clients_slug_response_200.additional_properties = d
        return get_oauth_clients_slug_response_200

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
