from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar(
    "T", bound="GetOauthProviderTemplatesResponse200TemplatesAdditionalPropertyIdentityMapping"
)


@_attrs_define
class GetOauthProviderTemplatesResponse200TemplatesAdditionalPropertyIdentityMapping:
    """
    Attributes:
        subject_field (str | Unset):
        email_field (str | Unset):
        name_field (str | Unset):
        avatar_field (str | Unset):
        verification_url (str | Unset):
        jwks_url (str | Unset):
        require_email_verified (bool | Unset):
        allowed_audiences (list[str] | Unset):
        secondary_email_url (str | Unset):
    """

    subject_field: str | Unset = UNSET
    email_field: str | Unset = UNSET
    name_field: str | Unset = UNSET
    avatar_field: str | Unset = UNSET
    verification_url: str | Unset = UNSET
    jwks_url: str | Unset = UNSET
    require_email_verified: bool | Unset = UNSET
    allowed_audiences: list[str] | Unset = UNSET
    secondary_email_url: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subject_field = self.subject_field

        email_field = self.email_field

        name_field = self.name_field

        avatar_field = self.avatar_field

        verification_url = self.verification_url

        jwks_url = self.jwks_url

        require_email_verified = self.require_email_verified

        allowed_audiences: list[str] | Unset = UNSET
        if not isinstance(self.allowed_audiences, Unset):
            allowed_audiences = self.allowed_audiences

        secondary_email_url = self.secondary_email_url

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if subject_field is not UNSET:
            field_dict["subjectField"] = subject_field
        if email_field is not UNSET:
            field_dict["emailField"] = email_field
        if name_field is not UNSET:
            field_dict["nameField"] = name_field
        if avatar_field is not UNSET:
            field_dict["avatarField"] = avatar_field
        if verification_url is not UNSET:
            field_dict["verificationUrl"] = verification_url
        if jwks_url is not UNSET:
            field_dict["jwksUrl"] = jwks_url
        if require_email_verified is not UNSET:
            field_dict["requireEmailVerified"] = require_email_verified
        if allowed_audiences is not UNSET:
            field_dict["allowedAudiences"] = allowed_audiences
        if secondary_email_url is not UNSET:
            field_dict["secondaryEmailUrl"] = secondary_email_url

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        subject_field = d.pop("subjectField", UNSET)

        email_field = d.pop("emailField", UNSET)

        name_field = d.pop("nameField", UNSET)

        avatar_field = d.pop("avatarField", UNSET)

        verification_url = d.pop("verificationUrl", UNSET)

        jwks_url = d.pop("jwksUrl", UNSET)

        require_email_verified = d.pop("requireEmailVerified", UNSET)

        allowed_audiences = cast(list[str], d.pop("allowedAudiences", UNSET))

        secondary_email_url = d.pop("secondaryEmailUrl", UNSET)

        get_oauth_provider_templates_response_200_templates_additional_property_identity_mapping = (
            cls(
                subject_field=subject_field,
                email_field=email_field,
                name_field=name_field,
                avatar_field=avatar_field,
                verification_url=verification_url,
                jwks_url=jwks_url,
                require_email_verified=require_email_verified,
                allowed_audiences=allowed_audiences,
                secondary_email_url=secondary_email_url,
            )
        )

        get_oauth_provider_templates_response_200_templates_additional_property_identity_mapping.additional_properties = d
        return (
            get_oauth_provider_templates_response_200_templates_additional_property_identity_mapping
        )

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
