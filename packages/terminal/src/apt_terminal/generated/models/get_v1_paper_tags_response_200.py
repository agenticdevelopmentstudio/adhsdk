from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.markdown_keyword_node import MarkdownKeywordNode


T = TypeVar("T", bound="GetV1PaperTagsResponse200")


@_attrs_define
class GetV1PaperTagsResponse200:
    """
    Attributes:
        items (list[str]): Tag labels, alphabetical.
        nodes (list[MarkdownKeywordNode]): The same labels with their row ids, in the same order.
        object_ (Literal['paper_tag'] | Unset):
    """

    items: list[str]
    nodes: list[MarkdownKeywordNode]
    object_: Literal["paper_tag"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        items = self.items

        nodes = []
        for nodes_item_data in self.nodes:
            nodes_item = nodes_item_data.to_dict()
            nodes.append(nodes_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "items": items,
                "nodes": nodes,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.markdown_keyword_node import MarkdownKeywordNode

        d = dict(src_dict)
        items = cast(list[str], d.pop("items"))

        nodes = []
        _nodes = d.pop("nodes")
        for nodes_item_data in _nodes:
            nodes_item = MarkdownKeywordNode.from_dict(nodes_item_data)

            nodes.append(nodes_item)

        object_ = cast(Literal["paper_tag"] | Unset, d.pop("object", UNSET))
        if object_ != "paper_tag" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'paper_tag', got '{object_}'")

        get_v1_paper_tags_response_200 = cls(
            items=items,
            nodes=nodes,
            object_=object_,
        )

        get_v1_paper_tags_response_200.additional_properties = d
        return get_v1_paper_tags_response_200

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
