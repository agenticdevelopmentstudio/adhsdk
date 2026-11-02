from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.markdown_category_node import MarkdownCategoryNode


T = TypeVar("T", bound="MarkdownCategoryTree")


@_attrs_define
class MarkdownCategoryTree:
    """
    Attributes:
        items (list[str]): Distinct category names, alphabetical.
        nodes (list[MarkdownCategoryNode]): The category rows, by sortOrder then name.
    """

    items: list[str]
    nodes: list[MarkdownCategoryNode]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        items = self.items

        nodes = []
        for nodes_item_data in self.nodes:
            nodes_item = nodes_item_data.to_dict()
            nodes.append(nodes_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "items": items,
                "nodes": nodes,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.markdown_category_node import MarkdownCategoryNode

        d = dict(src_dict)
        items = cast(list[str], d.pop("items"))

        nodes = []
        _nodes = d.pop("nodes")
        for nodes_item_data in _nodes:
            nodes_item = MarkdownCategoryNode.from_dict(nodes_item_data)

            nodes.append(nodes_item)

        markdown_category_tree = cls(
            items=items,
            nodes=nodes,
        )

        markdown_category_tree.additional_properties = d
        return markdown_category_tree

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
