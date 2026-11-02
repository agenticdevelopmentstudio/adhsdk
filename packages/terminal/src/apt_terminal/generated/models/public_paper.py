from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PublicPaper")


@_attrs_define
class PublicPaper:
    """
    Attributes:
        route (str):
        title (str):
        category (None | str):
        tags (list[str]):
        content (str): Full raw markdown, byte-exact.
        created_at (str):
        updated_at (str):
    """

    route: str
    title: str
    category: None | str
    tags: list[str]
    content: str
    created_at: str
    updated_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        route = self.route

        title = self.title

        category: None | str
        category = self.category

        tags = self.tags

        content = self.content

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "route": route,
                "title": title,
                "category": category,
                "tags": tags,
                "content": content,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        route = d.pop("route")

        title = d.pop("title")

        def _parse_category(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        category = _parse_category(d.pop("category"))

        tags = cast(list[str], d.pop("tags"))

        content = d.pop("content")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        public_paper = cls(
            route=route,
            title=title,
            category=category,
            tags=tags,
            content=content,
            created_at=created_at,
            updated_at=updated_at,
        )

        public_paper.additional_properties = d
        return public_paper

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
