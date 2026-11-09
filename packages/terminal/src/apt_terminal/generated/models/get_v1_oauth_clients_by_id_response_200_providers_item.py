from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_v1_oauth_clients_by_id_response_200_providers_item_auth_type import (
    GetV1OauthClientsByIdResponse200ProvidersItemAuthType,
)

T = TypeVar("T", bound="GetV1OauthClientsByIdResponse200ProvidersItem")


@_attrs_define
class GetV1OauthClientsByIdResponse200ProvidersItem:
    """
    Attributes:
        id (str):
        slug (str):
        name (str):
        auth_type (GetV1OauthClientsByIdResponse200ProvidersItemAuthType):
    """

    id: str
    slug: str
    name: str
    auth_type: GetV1OauthClientsByIdResponse200ProvidersItemAuthType
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        slug = self.slug

        name = self.name

        auth_type = self.auth_type.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "name": name,
                "auth_type": auth_type,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        slug = d.pop("slug")

        name = d.pop("name")

        auth_type = GetV1OauthClientsByIdResponse200ProvidersItemAuthType(d.pop("auth_type"))

        get_v1_oauth_clients_by_id_response_200_providers_item = cls(
            id=id,
            slug=slug,
            name=name,
            auth_type=auth_type,
        )

        get_v1_oauth_clients_by_id_response_200_providers_item.additional_properties = d
        return get_v1_oauth_clients_by_id_response_200_providers_item

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
