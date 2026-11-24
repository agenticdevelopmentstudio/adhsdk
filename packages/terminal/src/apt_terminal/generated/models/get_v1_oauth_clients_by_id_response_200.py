from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.get_v1_oauth_clients_by_id_response_200_client import (
        GetV1OauthClientsByIdResponse200Client,
    )
    from ..models.get_v1_oauth_clients_by_id_response_200_providers_item import (
        GetV1OauthClientsByIdResponse200ProvidersItem,
    )


T = TypeVar("T", bound="GetV1OauthClientsByIdResponse200")


@_attrs_define
class GetV1OauthClientsByIdResponse200:
    """
    Attributes:
        client (GetV1OauthClientsByIdResponse200Client):
        providers (list[GetV1OauthClientsByIdResponse200ProvidersItem]):
        object_ (Literal['oauth.client'] | Unset):
    """

    client: GetV1OauthClientsByIdResponse200Client
    providers: list[GetV1OauthClientsByIdResponse200ProvidersItem]
    object_: Literal["oauth.client"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        client = self.client.to_dict()

        providers = []
        for providers_item_data in self.providers:
            providers_item = providers_item_data.to_dict()
            providers.append(providers_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "client": client,
                "providers": providers,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_v1_oauth_clients_by_id_response_200_client import (
            GetV1OauthClientsByIdResponse200Client,
        )
        from ..models.get_v1_oauth_clients_by_id_response_200_providers_item import (
            GetV1OauthClientsByIdResponse200ProvidersItem,
        )

        d = dict(src_dict)
        client = GetV1OauthClientsByIdResponse200Client.from_dict(d.pop("client"))

        providers = []
        _providers = d.pop("providers")
        for providers_item_data in _providers:
            providers_item = GetV1OauthClientsByIdResponse200ProvidersItem.from_dict(
                providers_item_data
            )

            providers.append(providers_item)

        object_ = cast(Literal["oauth.client"] | Unset, d.pop("object", UNSET))
        if object_ != "oauth.client" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'oauth.client', got '{object_}'")

        get_v1_oauth_clients_by_id_response_200 = cls(
            client=client,
            providers=providers,
            object_=object_,
        )

        get_v1_oauth_clients_by_id_response_200.additional_properties = d
        return get_v1_oauth_clients_by_id_response_200

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
