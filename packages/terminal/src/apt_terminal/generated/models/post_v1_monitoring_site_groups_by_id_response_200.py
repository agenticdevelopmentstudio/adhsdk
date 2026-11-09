from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1MonitoringSiteGroupsByIdResponse200")


@_attrs_define
class PostV1MonitoringSiteGroupsByIdResponse200:
    """
    Attributes:
        id (str):
        user_id (str):
        author_kind (None | str):
        author_id (None | str):
        owner_kind (str):
        owner_id (str):
        name (str):
        slug (str):
        description (None | str):
        retention_days (int):
        display_order (int):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['monitoring.site_group'] | Unset):
    """

    id: str
    user_id: str
    author_kind: None | str
    author_id: None | str
    owner_kind: str
    owner_id: str
    name: str
    slug: str
    description: None | str
    retention_days: int
    display_order: int
    created: int
    updated: int
    object_: Literal["monitoring.site_group"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        user_id = self.user_id

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        name = self.name

        slug = self.slug

        description: None | str
        description = self.description

        retention_days = self.retention_days

        display_order = self.display_order

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "user_id": user_id,
                "author_kind": author_kind,
                "author_id": author_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "name": name,
                "slug": slug,
                "description": description,
                "retention_days": retention_days,
                "display_order": display_order,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        user_id = d.pop("user_id")

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

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        name = d.pop("name")

        slug = d.pop("slug")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        retention_days = d.pop("retention_days")

        display_order = d.pop("display_order")

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["monitoring.site_group"] | Unset, d.pop("object", UNSET))
        if object_ != "monitoring.site_group" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'monitoring.site_group', got '{object_}'")

        post_v1_monitoring_site_groups_by_id_response_200 = cls(
            id=id,
            user_id=user_id,
            author_kind=author_kind,
            author_id=author_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            name=name,
            slug=slug,
            description=description,
            retention_days=retention_days,
            display_order=display_order,
            created=created,
            updated=updated,
            object_=object_,
        )

        return post_v1_monitoring_site_groups_by_id_response_200
