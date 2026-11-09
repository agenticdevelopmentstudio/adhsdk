from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostV1OauthProvidersByIdBodyIdentityMappingClientSecretJwt")


@_attrs_define
class PostV1OauthProvidersByIdBodyIdentityMappingClientSecretJwt:
    """
    Attributes:
        team_id (str):
        key_id (str):
        audience (str):
    """

    team_id: str
    key_id: str
    audience: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        team_id = self.team_id

        key_id = self.key_id

        audience = self.audience

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "team_id": team_id,
                "key_id": key_id,
                "audience": audience,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        team_id = d.pop("team_id")

        key_id = d.pop("key_id")

        audience = d.pop("audience")

        post_v1_oauth_providers_by_id_body_identity_mapping_client_secret_jwt = cls(
            team_id=team_id,
            key_id=key_id,
            audience=audience,
        )

        post_v1_oauth_providers_by_id_body_identity_mapping_client_secret_jwt.additional_properties = d
        return post_v1_oauth_providers_by_id_body_identity_mapping_client_secret_jwt

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
