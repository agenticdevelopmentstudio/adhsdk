from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.patch_oauth_providers_slug_body_identity_mapping_response_mode import (
    PatchOauthProvidersSlugBodyIdentityMappingResponseMode,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.patch_oauth_providers_slug_body_identity_mapping_client_secret_jwt import (
        PatchOauthProvidersSlugBodyIdentityMappingClientSecretJwt,
    )


T = TypeVar("T", bound="PatchOauthProvidersSlugBodyIdentityMapping")


@_attrs_define
class PatchOauthProvidersSlugBodyIdentityMapping:
    """
    Attributes:
        subject_field (str):
        email_field (str):
        name_field (str):
        avatar_field (str):
        verification_url (str | Unset):
        require_email_verified (bool | Unset):
        email_verified_field (str | Unset):
        trusted_email_tenants (list[str] | Unset):
        allowed_audiences (list[str] | Unset):
        secondary_email_url (str | Unset):
        id_token_jwks_url (str | Unset):
        id_token_issuers (list[str] | Unset):
        response_mode (PatchOauthProvidersSlugBodyIdentityMappingResponseMode | Unset):
        client_secret_jwt (PatchOauthProvidersSlugBodyIdentityMappingClientSecretJwt | Unset):
    """

    subject_field: str
    email_field: str
    name_field: str
    avatar_field: str
    verification_url: str | Unset = UNSET
    require_email_verified: bool | Unset = UNSET
    email_verified_field: str | Unset = UNSET
    trusted_email_tenants: list[str] | Unset = UNSET
    allowed_audiences: list[str] | Unset = UNSET
    secondary_email_url: str | Unset = UNSET
    id_token_jwks_url: str | Unset = UNSET
    id_token_issuers: list[str] | Unset = UNSET
    response_mode: PatchOauthProvidersSlugBodyIdentityMappingResponseMode | Unset = UNSET
    client_secret_jwt: PatchOauthProvidersSlugBodyIdentityMappingClientSecretJwt | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subject_field = self.subject_field

        email_field = self.email_field

        name_field = self.name_field

        avatar_field = self.avatar_field

        verification_url = self.verification_url

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
                "subjectField": subject_field,
                "emailField": email_field,
                "nameField": name_field,
                "avatarField": avatar_field,
            }
        )
        if verification_url is not UNSET:
            field_dict["verificationUrl"] = verification_url
        if require_email_verified is not UNSET:
            field_dict["requireEmailVerified"] = require_email_verified
        if email_verified_field is not UNSET:
            field_dict["emailVerifiedField"] = email_verified_field
        if trusted_email_tenants is not UNSET:
            field_dict["trustedEmailTenants"] = trusted_email_tenants
        if allowed_audiences is not UNSET:
            field_dict["allowedAudiences"] = allowed_audiences
        if secondary_email_url is not UNSET:
            field_dict["secondaryEmailUrl"] = secondary_email_url
        if id_token_jwks_url is not UNSET:
            field_dict["idTokenJwksUrl"] = id_token_jwks_url
        if id_token_issuers is not UNSET:
            field_dict["idTokenIssuers"] = id_token_issuers
        if response_mode is not UNSET:
            field_dict["responseMode"] = response_mode
        if client_secret_jwt is not UNSET:
            field_dict["clientSecretJwt"] = client_secret_jwt

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.patch_oauth_providers_slug_body_identity_mapping_client_secret_jwt import (
            PatchOauthProvidersSlugBodyIdentityMappingClientSecretJwt,
        )

        d = dict(src_dict)
        subject_field = d.pop("subjectField")

        email_field = d.pop("emailField")

        name_field = d.pop("nameField")

        avatar_field = d.pop("avatarField")

        verification_url = d.pop("verificationUrl", UNSET)

        require_email_verified = d.pop("requireEmailVerified", UNSET)

        email_verified_field = d.pop("emailVerifiedField", UNSET)

        trusted_email_tenants = cast(list[str], d.pop("trustedEmailTenants", UNSET))

        allowed_audiences = cast(list[str], d.pop("allowedAudiences", UNSET))

        secondary_email_url = d.pop("secondaryEmailUrl", UNSET)

        id_token_jwks_url = d.pop("idTokenJwksUrl", UNSET)

        id_token_issuers = cast(list[str], d.pop("idTokenIssuers", UNSET))

        _response_mode = d.pop("responseMode", UNSET)
        response_mode: PatchOauthProvidersSlugBodyIdentityMappingResponseMode | Unset
        if isinstance(_response_mode, Unset):
            response_mode = UNSET
        else:
            response_mode = PatchOauthProvidersSlugBodyIdentityMappingResponseMode(_response_mode)

        _client_secret_jwt = d.pop("clientSecretJwt", UNSET)
        client_secret_jwt: PatchOauthProvidersSlugBodyIdentityMappingClientSecretJwt | Unset
        if isinstance(_client_secret_jwt, Unset):
            client_secret_jwt = UNSET
        else:
            client_secret_jwt = PatchOauthProvidersSlugBodyIdentityMappingClientSecretJwt.from_dict(
                _client_secret_jwt
            )

        patch_oauth_providers_slug_body_identity_mapping = cls(
            subject_field=subject_field,
            email_field=email_field,
            name_field=name_field,
            avatar_field=avatar_field,
            verification_url=verification_url,
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

        patch_oauth_providers_slug_body_identity_mapping.additional_properties = d
        return patch_oauth_providers_slug_body_identity_mapping

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
