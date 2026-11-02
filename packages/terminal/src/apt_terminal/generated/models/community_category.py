from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="CommunityCategory")


@_attrs_define
class CommunityCategory:
    """
    Attributes:
        id (str):
        community_id (str):
        slug (str):
        name (str):
        display_order (int):
        is_public (bool):
        is_archived (bool):
        created_at (str):
        updated_at (str):
        description (None | str | Unset):
        color (None | str | Unset):
        discussion_count (int | Unset): Live discussions filed under this category (public-only for anonymous callers).
        last_activity_at (None | str | Unset): Most recent activity across the category’s live discussions (null when
            empty).
    """

    id: str
    community_id: str
    slug: str
    name: str
    display_order: int
    is_public: bool
    is_archived: bool
    created_at: str
    updated_at: str
    description: None | str | Unset = UNSET
    color: None | str | Unset = UNSET
    discussion_count: int | Unset = UNSET
    last_activity_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        community_id = self.community_id

        slug = self.slug

        name = self.name

        display_order = self.display_order

        is_public = self.is_public

        is_archived = self.is_archived

        created_at = self.created_at

        updated_at = self.updated_at

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        color: None | str | Unset
        if isinstance(self.color, Unset):
            color = UNSET
        else:
            color = self.color

        discussion_count = self.discussion_count

        last_activity_at: None | str | Unset
        if isinstance(self.last_activity_at, Unset):
            last_activity_at = UNSET
        else:
            last_activity_at = self.last_activity_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "communityId": community_id,
                "slug": slug,
                "name": name,
                "displayOrder": display_order,
                "isPublic": is_public,
                "isArchived": is_archived,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if color is not UNSET:
            field_dict["color"] = color
        if discussion_count is not UNSET:
            field_dict["discussionCount"] = discussion_count
        if last_activity_at is not UNSET:
            field_dict["lastActivityAt"] = last_activity_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        community_id = d.pop("communityId")

        slug = d.pop("slug")

        name = d.pop("name")

        display_order = d.pop("displayOrder")

        is_public = d.pop("isPublic")

        is_archived = d.pop("isArchived")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        def _parse_color(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        color = _parse_color(d.pop("color", UNSET))

        discussion_count = d.pop("discussionCount", UNSET)

        def _parse_last_activity_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_activity_at = _parse_last_activity_at(d.pop("lastActivityAt", UNSET))

        community_category = cls(
            id=id,
            community_id=community_id,
            slug=slug,
            name=name,
            display_order=display_order,
            is_public=is_public,
            is_archived=is_archived,
            created_at=created_at,
            updated_at=updated_at,
            description=description,
            color=color,
            discussion_count=discussion_count,
            last_activity_at=last_activity_at,
        )

        community_category.additional_properties = d
        return community_category

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
