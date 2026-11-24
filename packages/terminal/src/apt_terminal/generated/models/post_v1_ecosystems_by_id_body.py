from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.ecosystem_auth_settings_update import EcosystemAuthSettingsUpdate
    from ..models.ecosystem_client_auth_update import EcosystemClientAuthUpdate


T = TypeVar("T", bound="PostV1EcosystemsByIdBody")


@_attrs_define
class PostV1EcosystemsByIdBody:
    """
    Attributes:
        owner_id (str | Unset):
        owner_kind (None | str | Unset):
        slug (str | Unset):
        name (str | Unset):
        description (str | Unset):
        region (str | Unset):
        dedicated_db_connection_id (None | str | Unset):
        primary_domain (str | Unset):
        is_default (bool | Unset):
        namespace_id (None | str | Unset):
        parent_id (None | str | Unset):
        archived_at (None | str | Unset):
        auth_settings (EcosystemAuthSettingsUpdate | Unset): A partial update — supply at least one field. Anything
            omitted is left as it was.
        client_auth (EcosystemClientAuthUpdate | Unset): Supply at least one key. `registration: null` removes the
            ecosystem registration. A registration for the platform ecosystem is a 400.
    """

    owner_id: str | Unset = UNSET
    owner_kind: None | str | Unset = UNSET
    slug: str | Unset = UNSET
    name: str | Unset = UNSET
    description: str | Unset = UNSET
    region: str | Unset = UNSET
    dedicated_db_connection_id: None | str | Unset = UNSET
    primary_domain: str | Unset = UNSET
    is_default: bool | Unset = UNSET
    namespace_id: None | str | Unset = UNSET
    parent_id: None | str | Unset = UNSET
    archived_at: None | str | Unset = UNSET
    auth_settings: EcosystemAuthSettingsUpdate | Unset = UNSET
    client_auth: EcosystemClientAuthUpdate | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        owner_id = self.owner_id

        owner_kind: None | str | Unset
        if isinstance(self.owner_kind, Unset):
            owner_kind = UNSET
        else:
            owner_kind = self.owner_kind

        slug = self.slug

        name = self.name

        description = self.description

        region = self.region

        dedicated_db_connection_id: None | str | Unset
        if isinstance(self.dedicated_db_connection_id, Unset):
            dedicated_db_connection_id = UNSET
        else:
            dedicated_db_connection_id = self.dedicated_db_connection_id

        primary_domain = self.primary_domain

        is_default = self.is_default

        namespace_id: None | str | Unset
        if isinstance(self.namespace_id, Unset):
            namespace_id = UNSET
        else:
            namespace_id = self.namespace_id

        parent_id: None | str | Unset
        if isinstance(self.parent_id, Unset):
            parent_id = UNSET
        else:
            parent_id = self.parent_id

        archived_at: None | str | Unset
        if isinstance(self.archived_at, Unset):
            archived_at = UNSET
        else:
            archived_at = self.archived_at

        auth_settings: dict[str, Any] | Unset = UNSET
        if not isinstance(self.auth_settings, Unset):
            auth_settings = self.auth_settings.to_dict()

        client_auth: dict[str, Any] | Unset = UNSET
        if not isinstance(self.client_auth, Unset):
            client_auth = self.client_auth.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if owner_id is not UNSET:
            field_dict["owner_id"] = owner_id
        if owner_kind is not UNSET:
            field_dict["owner_kind"] = owner_kind
        if slug is not UNSET:
            field_dict["slug"] = slug
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if region is not UNSET:
            field_dict["region"] = region
        if dedicated_db_connection_id is not UNSET:
            field_dict["dedicated_db_connection_id"] = dedicated_db_connection_id
        if primary_domain is not UNSET:
            field_dict["primary_domain"] = primary_domain
        if is_default is not UNSET:
            field_dict["is_default"] = is_default
        if namespace_id is not UNSET:
            field_dict["namespace_id"] = namespace_id
        if parent_id is not UNSET:
            field_dict["parent_id"] = parent_id
        if archived_at is not UNSET:
            field_dict["archived_at"] = archived_at
        if auth_settings is not UNSET:
            field_dict["auth_settings"] = auth_settings
        if client_auth is not UNSET:
            field_dict["client_auth"] = client_auth

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ecosystem_auth_settings_update import (
            EcosystemAuthSettingsUpdate,
        )
        from ..models.ecosystem_client_auth_update import EcosystemClientAuthUpdate

        d = dict(src_dict)
        owner_id = d.pop("owner_id", UNSET)

        def _parse_owner_kind(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        owner_kind = _parse_owner_kind(d.pop("owner_kind", UNSET))

        slug = d.pop("slug", UNSET)

        name = d.pop("name", UNSET)

        description = d.pop("description", UNSET)

        region = d.pop("region", UNSET)

        def _parse_dedicated_db_connection_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        dedicated_db_connection_id = _parse_dedicated_db_connection_id(
            d.pop("dedicated_db_connection_id", UNSET)
        )

        primary_domain = d.pop("primary_domain", UNSET)

        is_default = d.pop("is_default", UNSET)

        def _parse_namespace_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        namespace_id = _parse_namespace_id(d.pop("namespace_id", UNSET))

        def _parse_parent_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        parent_id = _parse_parent_id(d.pop("parent_id", UNSET))

        def _parse_archived_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        archived_at = _parse_archived_at(d.pop("archived_at", UNSET))

        _auth_settings = d.pop("auth_settings", UNSET)
        auth_settings: EcosystemAuthSettingsUpdate | Unset
        if isinstance(_auth_settings, Unset):
            auth_settings = UNSET
        else:
            auth_settings = EcosystemAuthSettingsUpdate.from_dict(_auth_settings)

        _client_auth = d.pop("client_auth", UNSET)
        client_auth: EcosystemClientAuthUpdate | Unset
        if isinstance(_client_auth, Unset):
            client_auth = UNSET
        else:
            client_auth = EcosystemClientAuthUpdate.from_dict(_client_auth)

        post_v1_ecosystems_by_id_body = cls(
            owner_id=owner_id,
            owner_kind=owner_kind,
            slug=slug,
            name=name,
            description=description,
            region=region,
            dedicated_db_connection_id=dedicated_db_connection_id,
            primary_domain=primary_domain,
            is_default=is_default,
            namespace_id=namespace_id,
            parent_id=parent_id,
            archived_at=archived_at,
            auth_settings=auth_settings,
            client_auth=client_auth,
        )

        post_v1_ecosystems_by_id_body.additional_properties = d
        return post_v1_ecosystems_by_id_body

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
