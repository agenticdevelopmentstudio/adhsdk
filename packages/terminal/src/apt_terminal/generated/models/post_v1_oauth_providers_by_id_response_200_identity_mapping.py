from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_oauth_providers_by_id_response_200_identity_mapping_response_mode import (
    PostV1OauthProvidersByIdResponse200IdentityMappingResponseMode,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_oauth_providers_by_id_response_200_identity_mapping_client_secret_jwt import (
        PostV1OauthProvidersByIdResponse200IdentityMappingClientSecretJwt,
    )


T = TypeVar("T", bound="PostV1OauthProvidersByIdResponse200IdentityMapping")


@_attrs_define
class PostV1OauthProvidersByIdResponse200IdentityMapping:
    """
    Attributes:
        subject_field (str):
        email_field (str):
        name_field (str):
        avatar_field (str):
        verification_url (str | Unset):
        jwks_url (str | Unset):
        require_email_verified (bool | Unset):
        email_verified_field (str | Unset):
        trusted_email_tenants (list[str] | Unset):
        allowed_audiences (list[str] | Unset):
        secondary_email_url (str | Unset):
        id_token_jwks_url (str | Unset):
        id_token_issuers (list[str] | Unset):
        response_mode (PostV1OauthProvidersByIdResponse200IdentityMappingResponseMode | Unset):
        client_secret_jwt (PostV1OauthProvidersByIdResponse200IdentityMappingClientSecretJwt | Unset):
    """

    subject_field: str
    email_field: str
    name_field: str
    avatar_field: str
    verification_url: str | Unset = UNSET
    jwks_url: str | Unset = UNSET
    require_email_verified: bool | Unset = UNSET
    email_verified_field: str | Unset = UNSET
    trusted_email_tenants: list[str] | Unset = UNSET
    allowed_audiences: list[str] | Unset = UNSET
    secondary_email_url: str | Unset = UNSET
    id_token_jwks_url: str | Unset = UNSET
    id_token_issuers: list[str] | Unset = UNSET
    response_mode: PostV1OauthProvidersByIdResponse200IdentityMappingResponseMode | Unset = UNSET
    client_secret_jwt: PostV1OauthProvidersByIdResponse200IdentityMappingClientSecretJwt | Unset = (
        UNSET
    )
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subject_field = self.subject_field

        email_field = self.email_field

        name_field = self.name_field

        avatar_field = self.avatar_field

        verification_url = self.verification_url

        jwks_url = self.jwks_url

        require_email_verified = self.require_email_verified

        email_verified_field = self.email_verified_field

        trusted_email_tenants: list[str] | Unset = UNSET
        if not isinstance(self.trusted_email_tenants, Unset):
            trusted_email_tenants = self.trusted_email_tenants

        allowed_audiences: list[str] | Unset = UNSET
        if not isinstance(self.allowed_audiences, Unset):
            allowed_audiences = self.allowed_audiences

        secondary_email_url = self.secondary_email_url

        id_token_jwks_url = self.id_token_jwks_url

        id_token_issuers: list[str] | Unset = UNSET
        if not isinstance(self.id_token_issuers, Unset):
            id_token_issuers = self.id_token_issuers

        response_mode: str | Unset = UNSET
        if not isinstance(self.response_mode, Unset):
            response_mode = self.response_mode.value

        client_secret_jwt: dict[str, Any] | Unset = UNSET
        if not isinstance(self.client_secret_jwt, Unset):
            client_secret_jwt = self.client_secret_jwt.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subject_field": subject_field,
                "email_field": email_field,
                "name_field": name_field,
                "avatar_field": avatar_field,
            }
        )
        if verification_url is not UNSET:
            field_dict["verification_url"] = verification_url
        if jwks_url is not UNSET:
            field_dict["jwks_url"] = jwks_url
        if require_email_verified is not UNSET:
            field_dict["require_email_verified"] = require_email_verified
        if email_verified_field is not UNSET:
            field_dict["email_verified_field"] = email_verified_field
        if trusted_email_tenants is not UNSET:
            field_dict["trusted_email_tenants"] = trusted_email_tenants
        if allowed_audiences is not UNSET:
            field_dict["allowed_audiences"] = allowed_audiences
        if secondary_email_url is not UNSET:
            field_dict["secondary_email_url"] = secondary_email_url
        if id_token_jwks_url is not UNSET:
            field_dict["id_token_jwks_url"] = id_token_jwks_url
        if id_token_issuers is not UNSET:
            field_dict["id_token_issuers"] = id_token_issuers
        if response_mode is not UNSET:
            field_dict["response_mode"] = response_mode
        if client_secret_jwt is not UNSET:
            field_dict["client_secret_jwt"] = client_secret_jwt

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_oauth_providers_by_id_response_200_identity_mapping_client_secret_jwt import (
            PostV1OauthProvidersByIdResponse200IdentityMappingClientSecretJwt,
        )

        d = dict(src_dict)
        subject_field = d.pop("subject_field")

        email_field = d.pop("email_field")

        name_field = d.pop("name_field")

        avatar_field = d.pop("avatar_field")

        verification_url = d.pop("verification_url", UNSET)

        jwks_url = d.pop("jwks_url", UNSET)

        require_email_verified = d.pop("require_email_verified", UNSET)

        email_verified_field = d.pop("email_verified_field", UNSET)

        trusted_email_tenants = cast(list[str], d.pop("trusted_email_tenants", UNSET))

        allowed_audiences = cast(list[str], d.pop("allowed_audiences", UNSET))

        secondary_email_url = d.pop("secondary_email_url", UNSET)

        id_token_jwks_url = d.pop("id_token_jwks_url", UNSET)

        id_token_issuers = cast(list[str], d.pop("id_token_issuers", UNSET))

        _response_mode = d.pop("response_mode", UNSET)
        response_mode: PostV1OauthProvidersByIdResponse200IdentityMappingResponseMode | Unset
        if isinstance(_response_mode, Unset):
            response_mode = UNSET
        else:
            response_mode = PostV1OauthProvidersByIdResponse200IdentityMappingResponseMode(
                _response_mode
            )

        _client_secret_jwt = d.pop("client_secret_jwt", UNSET)
        client_secret_jwt: PostV1OauthProvidersByIdResponse200IdentityMappingClientSecretJwt | Unset
        if isinstance(_client_secret_jwt, Unset):
            client_secret_jwt = UNSET
        else:
            client_secret_jwt = (
                PostV1OauthProvidersByIdResponse200IdentityMappingClientSecretJwt.from_dict(
                    _client_secret_jwt
                )
            )

        post_v1_oauth_providers_by_id_response_200_identity_mapping = cls(
            subject_field=subject_field,
            email_field=email_field,
            name_field=name_field,
            avatar_field=avatar_field,
            verification_url=verification_url,
            jwks_url=jwks_url,
            require_email_verified=require_email_verified,
            email_verified_field=email_verified_field,
            trusted_email_tenants=trusted_email_tenants,
            allowed_audiences=allowed_audiences,
            secondary_email_url=secondary_email_url,
            id_token_jwks_url=id_token_jwks_url,
            id_token_issuers=id_token_issuers,
            response_mode=response_mode,
            client_secret_jwt=client_secret_jwt,
        )

        post_v1_oauth_providers_by_id_response_200_identity_mapping.additional_properties = d
        return post_v1_oauth_providers_by_id_response_200_identity_mapping

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
