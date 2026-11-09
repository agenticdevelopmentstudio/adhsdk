from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1EcosystemsResponse201")


@_attrs_define
class PostV1EcosystemsResponse201:
    """
    Attributes:
        id (str):
        owner_id (str):
        owner_kind (None | str):
        slug (str):
        name (str):
        description (str):
        region (str):
        dedicated_db_connection_id (None | str):
        primary_domain (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        is_deleted (bool):
        is_default (bool):
        type_ (str):
        namespace_id (None | str):
        parent_id (None | str):
        archived_at (None | str):
        is_infrastructure (bool): Whether this is a principal's own ecosystem: true exactly when `type` is `workspace`
            or `persona`. Derived from `type`; read `type` instead.
        object_ (Literal['ecosystem'] | Unset):
    """

    id: str
    owner_id: str
    owner_kind: None | str
    slug: str
    name: str
    description: str
    region: str
    dedicated_db_connection_id: None | str
    primary_domain: str
    created: int
    updated: int
    is_deleted: bool
    is_default: bool
    type_: str
    namespace_id: None | str
    parent_id: None | str
    archived_at: None | str
    is_infrastructure: bool
    object_: Literal["ecosystem"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        owner_id = self.owner_id

        owner_kind: None | str
        owner_kind = self.owner_kind

        slug = self.slug

        name = self.name

        description = self.description

        region = self.region

        dedicated_db_connection_id: None | str
        dedicated_db_connection_id = self.dedicated_db_connection_id

        primary_domain = self.primary_domain

        created = self.created

        updated = self.updated

        is_deleted = self.is_deleted

        is_default = self.is_default

        type_ = self.type_

        namespace_id: None | str
        namespace_id = self.namespace_id

        parent_id: None | str
        parent_id = self.parent_id

        archived_at: None | str
        archived_at = self.archived_at

        is_infrastructure = self.is_infrastructure

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "owner_id": owner_id,
                "owner_kind": owner_kind,
                "slug": slug,
                "name": name,
                "description": description,
                "region": region,
                "dedicated_db_connection_id": dedicated_db_connection_id,
                "primary_domain": primary_domain,
                "created": created,
                "updated": updated,
                "is_deleted": is_deleted,
                "is_default": is_default,
                "type": type_,
                "namespace_id": namespace_id,
                "parent_id": parent_id,
                "archived_at": archived_at,
                "is_infrastructure": is_infrastructure,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        owner_id = d.pop("owner_id")

        def _parse_owner_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        owner_kind = _parse_owner_kind(d.pop("owner_kind"))

        slug = d.pop("slug")

        name = d.pop("name")

        description = d.pop("description")

        region = d.pop("region")

        def _parse_dedicated_db_connection_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        dedicated_db_connection_id = _parse_dedicated_db_connection_id(
            d.pop("dedicated_db_connection_id")
        )

        primary_domain = d.pop("primary_domain")

        created = d.pop("created")

        updated = d.pop("updated")

        is_deleted = d.pop("is_deleted")

        is_default = d.pop("is_default")

        type_ = d.pop("type")

        def _parse_namespace_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        namespace_id = _parse_namespace_id(d.pop("namespace_id"))

        def _parse_parent_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        parent_id = _parse_parent_id(d.pop("parent_id"))

        def _parse_archived_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        archived_at = _parse_archived_at(d.pop("archived_at"))

        is_infrastructure = d.pop("is_infrastructure")

        object_ = cast(Literal["ecosystem"] | Unset, d.pop("object", UNSET))
        if object_ != "ecosystem" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'ecosystem', got '{object_}'")

        post_v1_ecosystems_response_201 = cls(
            id=id,
            owner_id=owner_id,
            owner_kind=owner_kind,
            slug=slug,
            name=name,
            description=description,
            region=region,
            dedicated_db_connection_id=dedicated_db_connection_id,
            primary_domain=primary_domain,
            created=created,
            updated=updated,
            is_deleted=is_deleted,
            is_default=is_default,
            type_=type_,
            namespace_id=namespace_id,
            parent_id=parent_id,
            archived_at=archived_at,
            is_infrastructure=is_infrastructure,
            object_=object_,
        )

        return post_v1_ecosystems_response_201
