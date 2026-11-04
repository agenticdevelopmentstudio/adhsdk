from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetTeamTeamsResponse200Item")


@_attrs_define
class GetTeamTeamsResponse200Item:
    """
    Attributes:
        id (str):
        owner_kind (str):
        owner_id (str):
        slug (str):
        name (str):
        description (str):
        created_by (None | str):
        author_kind (None | str):
        author_id (None | str):
        created_at (str):
        updated_at (str):
        is_deleted (bool):
    """

    id: str
    owner_kind: str
    owner_id: str
    slug: str
    name: str
    description: str
    created_by: None | str
    author_kind: None | str
    author_id: None | str
    created_at: str
    updated_at: str
    is_deleted: bool

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        slug = self.slug

        name = self.name

        description = self.description

        created_by: None | str
        created_by = self.created_by

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        created_at = self.created_at

        updated_at = self.updated_at

        is_deleted = self.is_deleted

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "slug": slug,
                "name": name,
                "description": description,
                "createdBy": created_by,
                "authorKind": author_kind,
                "authorId": author_id,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "isDeleted": is_deleted,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        slug = d.pop("slug")

        name = d.pop("name")

        description = d.pop("description")

        def _parse_created_by(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        created_by = _parse_created_by(d.pop("createdBy"))

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("authorKind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("authorId"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        is_deleted = d.pop("isDeleted")

        get_team_teams_response_200_item = cls(
            id=id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            slug=slug,
            name=name,
            description=description,
            created_by=created_by,
            author_kind=author_kind,
            author_id=author_id,
            created_at=created_at,
            updated_at=updated_at,
            is_deleted=is_deleted,
        )

        return get_team_teams_response_200_item
