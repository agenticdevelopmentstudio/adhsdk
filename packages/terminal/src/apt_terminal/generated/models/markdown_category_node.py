from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="MarkdownCategoryNode")


@_attrs_define
class MarkdownCategoryNode:
    """
    Attributes:
        id (str):
        name (str):
        parent_ids (list[str]): Every category this one sits under (content.category_edges). Empty for an unfiled
            category — there is no null sentinel. A category may appear under several parents at once, so a consumer folding
            this into a tree renders the same node in more than one place. Parent ids that are not themselves in `nodes` are
            already filtered out, and the write path rejects cycles, so the fold terminates.
        sort_order (int): Order among the unfiled/root categories (0 unless set through the generic CRUD). Order among
            one parent's children lives on the edge.
    """

    id: str
    name: str
    parent_ids: list[str]
    sort_order: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        name = self.name

        parent_ids = self.parent_ids

        sort_order = self.sort_order

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "parentIds": parent_ids,
                "sortOrder": sort_order,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        name = d.pop("name")

        parent_ids = cast(list[str], d.pop("parentIds"))

        sort_order = d.pop("sortOrder")

        markdown_category_node = cls(
            id=id,
            name=name,
            parent_ids=parent_ids,
            sort_order=sort_order,
        )

        markdown_category_node.additional_properties = d
        return markdown_category_node

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
