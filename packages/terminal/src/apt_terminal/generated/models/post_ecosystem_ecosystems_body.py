from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostEcosystemEcosystemsBody")


@_attrs_define
class PostEcosystemEcosystemsBody:
    """
    Attributes:
        slug (str):
        name (str):
        owner_id (str | Unset):
        owner_kind (None | str | Unset):
        description (str | Unset):
        region (str | Unset):
        dedicated_db_connection_id (None | str | Unset):
        primary_domain (str | Unset):
        is_default (bool | Unset):
        is_infrastructure (bool | Unset):
        namespace_id (None | str | Unset):
        parent_id (None | str | Unset):
        archived_at (None | str | Unset):
        id (str | Unset):
    """

    slug: str
    name: str
    owner_id: str | Unset = UNSET
    owner_kind: None | str | Unset = UNSET
    description: str | Unset = UNSET
    region: str | Unset = UNSET
    dedicated_db_connection_id: None | str | Unset = UNSET
    primary_domain: str | Unset = UNSET
    is_default: bool | Unset = UNSET
    is_infrastructure: bool | Unset = UNSET
    namespace_id: None | str | Unset = UNSET
    parent_id: None | str | Unset = UNSET
    archived_at: None | str | Unset = UNSET
    id: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        owner_id = self.owner_id

        owner_kind: None | str | Unset
        if isinstance(self.owner_kind, Unset):
            owner_kind = UNSET
        else:
            owner_kind = self.owner_kind

        description = self.description

        region = self.region

        dedicated_db_connection_id: None | str | Unset
        if isinstance(self.dedicated_db_connection_id, Unset):
            dedicated_db_connection_id = UNSET
        else:
            dedicated_db_connection_id = self.dedicated_db_connection_id

        primary_domain = self.primary_domain

        is_default = self.is_default

        is_infrastructure = self.is_infrastructure

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

        id = self.id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "slug": slug,
                "name": name,
            }
        )
        if owner_id is not UNSET:
            field_dict["ownerId"] = owner_id
        if owner_kind is not UNSET:
            field_dict["ownerKind"] = owner_kind
        if description is not UNSET:
            field_dict["description"] = description
        if region is not UNSET:
            field_dict["region"] = region
        if dedicated_db_connection_id is not UNSET:
            field_dict["dedicatedDbConnectionId"] = dedicated_db_connection_id
        if primary_domain is not UNSET:
            field_dict["primaryDomain"] = primary_domain
        if is_default is not UNSET:
            field_dict["isDefault"] = is_default
        if is_infrastructure is not UNSET:
            field_dict["isInfrastructure"] = is_infrastructure
        if namespace_id is not UNSET:
            field_dict["namespaceId"] = namespace_id
        if parent_id is not UNSET:
            field_dict["parentId"] = parent_id
        if archived_at is not UNSET:
            field_dict["archivedAt"] = archived_at
        if id is not UNSET:
            field_dict["id"] = id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        owner_id = d.pop("ownerId", UNSET)

        def _parse_owner_kind(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        owner_kind = _parse_owner_kind(d.pop("ownerKind", UNSET))

        description = d.pop("description", UNSET)

        region = d.pop("region", UNSET)

        def _parse_dedicated_db_connection_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        dedicated_db_connection_id = _parse_dedicated_db_connection_id(
            d.pop("dedicatedDbConnectionId", UNSET)
        )

        primary_domain = d.pop("primaryDomain", UNSET)

        is_default = d.pop("isDefault", UNSET)

        is_infrastructure = d.pop("isInfrastructure", UNSET)

        def _parse_namespace_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        namespace_id = _parse_namespace_id(d.pop("namespaceId", UNSET))

        def _parse_parent_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        parent_id = _parse_parent_id(d.pop("parentId", UNSET))

        def _parse_archived_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        archived_at = _parse_archived_at(d.pop("archivedAt", UNSET))

        id = d.pop("id", UNSET)

        post_ecosystem_ecosystems_body = cls(
            slug=slug,
            name=name,
            owner_id=owner_id,
            owner_kind=owner_kind,
            description=description,
            region=region,
            dedicated_db_connection_id=dedicated_db_connection_id,
            primary_domain=primary_domain,
            is_default=is_default,
            is_infrastructure=is_infrastructure,
            namespace_id=namespace_id,
            parent_id=parent_id,
            archived_at=archived_at,
            id=id,
        )

        return post_ecosystem_ecosystems_body
