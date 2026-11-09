from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PublicPaperSummary")


@_attrs_define
class PublicPaperSummary:
    """
    Attributes:
        route (str):
        title (str):
        category (None | str):
        tags (list[str]):
        updated (int): Unix timestamp, in seconds.
    """

    route: str
    title: str
    category: None | str
    tags: list[str]
    updated: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        route = self.route

        title = self.title

        category: None | str
        category = self.category

        tags = self.tags

        updated = self.updated

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "route": route,
                "title": title,
                "category": category,
                "tags": tags,
                "updated": updated,
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

        updated = d.pop("updated")

        public_paper_summary = cls(
            route=route,
            title=title,
            category=category,
            tags=tags,
            updated=updated,
        )

        public_paper_summary.additional_properties = d
        return public_paper_summary

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
