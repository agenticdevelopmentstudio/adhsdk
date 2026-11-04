from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_oauth_signin_discovery_response_200_signup_mode import (
    GetOauthSigninDiscoveryResponse200SignupMode,
)

if TYPE_CHECKING:
    from ..models.get_oauth_signin_discovery_response_200_clients_item import (
        GetOauthSigninDiscoveryResponse200ClientsItem,
    )
    from ..models.get_oauth_signin_discovery_response_200_providers_item import (
        GetOauthSigninDiscoveryResponse200ProvidersItem,
    )


T = TypeVar("T", bound="GetOauthSigninDiscoveryResponse200")


@_attrs_define
class GetOauthSigninDiscoveryResponse200:
    """
    Attributes:
        issuer (str):
        authorization_endpoint (str):
        token_endpoint (str):
        ecosystem_id (str):
        ecosystem_name (str):
        clients (list[GetOauthSigninDiscoveryResponse200ClientsItem]):
        login_enabled (bool):
        signup_mode (GetOauthSigninDiscoveryResponse200SignupMode):
        password_enabled (bool):
        providers (list[GetOauthSigninDiscoveryResponse200ProvidersItem]):
    """

    issuer: str
    authorization_endpoint: str
    token_endpoint: str
    ecosystem_id: str
    ecosystem_name: str
    clients: list[GetOauthSigninDiscoveryResponse200ClientsItem]
    login_enabled: bool
    signup_mode: GetOauthSigninDiscoveryResponse200SignupMode
    password_enabled: bool
    providers: list[GetOauthSigninDiscoveryResponse200ProvidersItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        issuer = self.issuer

        authorization_endpoint = self.authorization_endpoint

        token_endpoint = self.token_endpoint

        ecosystem_id = self.ecosystem_id

        ecosystem_name = self.ecosystem_name

        clients = []
        for clients_item_data in self.clients:
            clients_item = clients_item_data.to_dict()
            clients.append(clients_item)

        login_enabled = self.login_enabled

        signup_mode = self.signup_mode.value

        password_enabled = self.password_enabled

        providers = []
        for providers_item_data in self.providers:
            providers_item = providers_item_data.to_dict()
            providers.append(providers_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "issuer": issuer,
                "authorizationEndpoint": authorization_endpoint,
                "tokenEndpoint": token_endpoint,
                "ecosystemId": ecosystem_id,
                "ecosystemName": ecosystem_name,
                "clients": clients,
                "loginEnabled": login_enabled,
                "signupMode": signup_mode,
                "passwordEnabled": password_enabled,
                "providers": providers,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_oauth_signin_discovery_response_200_clients_item import (
            GetOauthSigninDiscoveryResponse200ClientsItem,
        )
        from ..models.get_oauth_signin_discovery_response_200_providers_item import (
            GetOauthSigninDiscoveryResponse200ProvidersItem,
        )

        d = dict(src_dict)
        issuer = d.pop("issuer")

        authorization_endpoint = d.pop("authorizationEndpoint")

        token_endpoint = d.pop("tokenEndpoint")

        ecosystem_id = d.pop("ecosystemId")

        ecosystem_name = d.pop("ecosystemName")

        clients = []
        _clients = d.pop("clients")
        for clients_item_data in _clients:
            clients_item = GetOauthSigninDiscoveryResponse200ClientsItem.from_dict(
                clients_item_data
            )

            clients.append(clients_item)

        login_enabled = d.pop("loginEnabled")

        signup_mode = GetOauthSigninDiscoveryResponse200SignupMode(d.pop("signupMode"))

        password_enabled = d.pop("passwordEnabled")

        providers = []
        _providers = d.pop("providers")
        for providers_item_data in _providers:
            providers_item = GetOauthSigninDiscoveryResponse200ProvidersItem.from_dict(
                providers_item_data
            )

            providers.append(providers_item)

        get_oauth_signin_discovery_response_200 = cls(
            issuer=issuer,
            authorization_endpoint=authorization_endpoint,
            token_endpoint=token_endpoint,
            ecosystem_id=ecosystem_id,
            ecosystem_name=ecosystem_name,
            clients=clients,
            login_enabled=login_enabled,
            signup_mode=signup_mode,
            password_enabled=password_enabled,
            providers=providers,
        )

        get_oauth_signin_discovery_response_200.additional_properties = d
        return get_oauth_signin_discovery_response_200

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
