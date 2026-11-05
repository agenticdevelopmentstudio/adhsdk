from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetEcosystemEcosystemsIdResponse200")


@_attrs_define
class GetEcosystemEcosystemsIdResponse200:
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
        created_at (str):
        updated_at (str):
        is_deleted (bool):
        is_default (bool):
        is_infrastructure (bool):
        type_ (str):
        namespace_id (None | str):
        parent_id (None | str):
        archived_at (None | str):
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
    created_at: str
    updated_at: str
    is_deleted: bool
    is_default: bool
    is_infrastructure: bool
    type_: str
    namespace_id: None | str
    parent_id: None | str
    archived_at: None | str

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

        created_at = self.created_at

        updated_at = self.updated_at

        is_deleted = self.is_deleted

        is_default = self.is_default

        is_infrastructure = self.is_infrastructure

        type_ = self.type_

        namespace_id: None | str
        namespace_id = self.namespace_id

        parent_id: None | str
        parent_id = self.parent_id

        archived_at: None | str
        archived_at = self.archived_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ownerId": owner_id,
                "ownerKind": owner_kind,
                "slug": slug,
                "name": name,
                "description": description,
                "region": region,
                "dedicatedDbConnectionId": dedicated_db_connection_id,
                "primaryDomain": primary_domain,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "isDeleted": is_deleted,
                "isDefault": is_default,
                "isInfrastructure": is_infrastructure,
                "type": type_,
                "namespaceId": namespace_id,
                "parentId": parent_id,
                "archivedAt": archived_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        owner_id = d.pop("ownerId")

        def _parse_owner_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        owner_kind = _parse_owner_kind(d.pop("ownerKind"))

        slug = d.pop("slug")

        name = d.pop("name")

        description = d.pop("description")

        region = d.pop("region")

        def _parse_dedicated_db_connection_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        dedicated_db_connection_id = _parse_dedicated_db_connection_id(
            d.pop("dedicatedDbConnectionId")
        )

        primary_domain = d.pop("primaryDomain")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        is_deleted = d.pop("isDeleted")

        is_default = d.pop("isDefault")

        is_infrastructure = d.pop("isInfrastructure")

        type_ = d.pop("type")

        def _parse_namespace_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        namespace_id = _parse_namespace_id(d.pop("namespaceId"))

        def _parse_parent_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        parent_id = _parse_parent_id(d.pop("parentId"))

        def _parse_archived_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        archived_at = _parse_archived_at(d.pop("archivedAt"))

        get_ecosystem_ecosystems_id_response_200 = cls(
            id=id,
            owner_id=owner_id,
            owner_kind=owner_kind,
            slug=slug,
            name=name,
            description=description,
            region=region,
            dedicated_db_connection_id=dedicated_db_connection_id,
            primary_domain=primary_domain,
            created_at=created_at,
            updated_at=updated_at,
            is_deleted=is_deleted,
            is_default=is_default,
            is_infrastructure=is_infrastructure,
            type_=type_,
            namespace_id=namespace_id,
            parent_id=parent_id,
            archived_at=archived_at,
        )

        return get_ecosystem_ecosystems_id_response_200
