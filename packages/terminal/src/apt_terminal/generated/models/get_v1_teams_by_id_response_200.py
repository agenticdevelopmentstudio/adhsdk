from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1TeamsByIdResponse200")


@_attrs_define
class GetV1TeamsByIdResponse200:
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
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        is_deleted (bool):
        object_ (Literal['team'] | Unset):
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
    created: int
    updated: int
    is_deleted: bool
    object_: Literal["team"] | Unset = UNSET

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

        created = self.created

        updated = self.updated

        is_deleted = self.is_deleted

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "slug": slug,
                "name": name,
                "description": description,
                "created_by": created_by,
                "author_kind": author_kind,
                "author_id": author_id,
                "created": created,
                "updated": updated,
                "is_deleted": is_deleted,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        slug = d.pop("slug")

        name = d.pop("name")

        description = d.pop("description")

        def _parse_created_by(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        created_by = _parse_created_by(d.pop("created_by"))

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("author_kind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("author_id"))

        created = d.pop("created")

        updated = d.pop("updated")

        is_deleted = d.pop("is_deleted")

        object_ = cast(Literal["team"] | Unset, d.pop("object", UNSET))
        if object_ != "team" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'team', got '{object_}'")

        get_v1_teams_by_id_response_200 = cls(
            id=id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            slug=slug,
            name=name,
            description=description,
            created_by=created_by,
            author_kind=author_kind,
            author_id=author_id,
            created=created,
            updated=updated,
            is_deleted=is_deleted,
            object_=object_,
        )

        return get_v1_teams_by_id_response_200
