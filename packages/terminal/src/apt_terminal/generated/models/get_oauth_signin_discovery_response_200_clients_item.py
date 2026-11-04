from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.get_oauth_signin_discovery_response_200_clients_item_providers_item import (
        GetOauthSigninDiscoveryResponse200ClientsItemProvidersItem,
    )


T = TypeVar("T", bound="GetOauthSigninDiscoveryResponse200ClientsItem")


@_attrs_define
class GetOauthSigninDiscoveryResponse200ClientsItem:
    """
    Attributes:
        client_id (str):
        name (str):
        redirect_uris (list[str]):
        providers (list[GetOauthSigninDiscoveryResponse200ClientsItemProvidersItem]):
    """

    client_id: str
    name: str
    redirect_uris: list[str]
    providers: list[GetOauthSigninDiscoveryResponse200ClientsItemProvidersItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        client_id = self.client_id

        name = self.name

        redirect_uris = self.redirect_uris

        providers = []
        for providers_item_data in self.providers:
            providers_item = providers_item_data.to_dict()
            providers.append(providers_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "clientId": client_id,
                "name": name,
                "redirectUris": redirect_uris,
                "providers": providers,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_oauth_signin_discovery_response_200_clients_item_providers_item import (
            GetOauthSigninDiscoveryResponse200ClientsItemProvidersItem,
        )

        d = dict(src_dict)
        client_id = d.pop("clientId")

        name = d.pop("name")

        redirect_uris = cast(list[str], d.pop("redirectUris"))

        providers = []
        _providers = d.pop("providers")
        for providers_item_data in _providers:
            providers_item = GetOauthSigninDiscoveryResponse200ClientsItemProvidersItem.from_dict(
                providers_item_data
            )

            providers.append(providers_item)

        get_oauth_signin_discovery_response_200_clients_item = cls(
            client_id=client_id,
            name=name,
            redirect_uris=redirect_uris,
            providers=providers,
        )

        get_oauth_signin_discovery_response_200_clients_item.additional_properties = d
        return get_oauth_signin_discovery_response_200_clients_item

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
