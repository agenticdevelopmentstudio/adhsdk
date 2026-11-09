from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1EcosystemsBody")


@_attrs_define
class PostV1EcosystemsBody:
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
            field_dict["owner_id"] = owner_id
        if owner_kind is not UNSET:
            field_dict["owner_kind"] = owner_kind
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
        if id is not UNSET:
            field_dict["id"] = id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        owner_id = d.pop("owner_id", UNSET)

        def _parse_owner_kind(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        owner_kind = _parse_owner_kind(d.pop("owner_kind", UNSET))

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

        id = d.pop("id", UNSET)

        post_v1_ecosystems_body = cls(
            slug=slug,
            name=name,
            owner_id=owner_id,
            owner_kind=owner_kind,
            description=description,
            region=region,
            dedicated_db_connection_id=dedicated_db_connection_id,
            primary_domain=primary_domain,
            is_default=is_default,
            namespace_id=namespace_id,
            parent_id=parent_id,
            archived_at=archived_at,
            id=id,
        )

        return post_v1_ecosystems_body
