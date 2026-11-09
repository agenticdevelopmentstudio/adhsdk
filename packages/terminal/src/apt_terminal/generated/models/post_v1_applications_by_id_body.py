from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.application_client_auth_update import ApplicationClientAuthUpdate
    from ..models.post_v1_applications_by_id_body_schema_grants import (
        PostV1ApplicationsByIdBodySchemaGrants,
    )


T = TypeVar("T", bound="PostV1ApplicationsByIdBody")


@_attrs_define
class PostV1ApplicationsByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        slug (str | Unset):
        display_name (str | Unset):
        consumer_kind (str | Unset):
        platform (str | Unset):
        client_auth (ApplicationClientAuthUpdate | Unset): `registration: null` removes the application registration.
        schema_grants (PostV1ApplicationsByIdBodySchemaGrants | Unset): Updates `schema_grants`.
    """

    ecosystem_id: str | Unset = UNSET
    slug: str | Unset = UNSET
    display_name: str | Unset = UNSET
    consumer_kind: str | Unset = UNSET
    platform: str | Unset = UNSET
    client_auth: ApplicationClientAuthUpdate | Unset = UNSET
    schema_grants: PostV1ApplicationsByIdBodySchemaGrants | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ecosystem_id = self.ecosystem_id

        slug = self.slug

        display_name = self.display_name

        consumer_kind = self.consumer_kind

        platform = self.platform

        client_auth: dict[str, Any] | Unset = UNSET
        if not isinstance(self.client_auth, Unset):
            client_auth = self.client_auth.to_dict()

        schema_grants: dict[str, Any] | Unset = UNSET
        if not isinstance(self.schema_grants, Unset):
            schema_grants = self.schema_grants.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if slug is not UNSET:
            field_dict["slug"] = slug
        if display_name is not UNSET:
            field_dict["display_name"] = display_name
        if consumer_kind is not UNSET:
            field_dict["consumer_kind"] = consumer_kind
        if platform is not UNSET:
            field_dict["platform"] = platform
        if client_auth is not UNSET:
            field_dict["client_auth"] = client_auth
        if schema_grants is not UNSET:
            field_dict["schema_grants"] = schema_grants

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.application_client_auth_update import (
            ApplicationClientAuthUpdate,
        )
        from ..models.post_v1_applications_by_id_body_schema_grants import (
            PostV1ApplicationsByIdBodySchemaGrants,
        )

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        slug = d.pop("slug", UNSET)

        display_name = d.pop("display_name", UNSET)

        consumer_kind = d.pop("consumer_kind", UNSET)

        platform = d.pop("platform", UNSET)

        _client_auth = d.pop("client_auth", UNSET)
        client_auth: ApplicationClientAuthUpdate | Unset
        if isinstance(_client_auth, Unset):
            client_auth = UNSET
        else:
            client_auth = ApplicationClientAuthUpdate.from_dict(_client_auth)

        _schema_grants = d.pop("schema_grants", UNSET)
        schema_grants: PostV1ApplicationsByIdBodySchemaGrants | Unset
        if isinstance(_schema_grants, Unset):
            schema_grants = UNSET
        else:
            schema_grants = PostV1ApplicationsByIdBodySchemaGrants.from_dict(_schema_grants)

        post_v1_applications_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            slug=slug,
            display_name=display_name,
            consumer_kind=consumer_kind,
            platform=platform,
            client_auth=client_auth,
            schema_grants=schema_grants,
        )

        post_v1_applications_by_id_body.additional_properties = d
        return post_v1_applications_by_id_body

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
