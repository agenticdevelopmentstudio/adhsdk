from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1PaperCategoriesResponse200")


@_attrs_define
class PostV1PaperCategoriesResponse200:
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
        object_ (Literal['paper_category'] | Unset):
    """

    id: str
    name: str
    parent_ids: list[str]
    sort_order: int
    object_: Literal["paper_category"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        name = self.name

        parent_ids = self.parent_ids

        sort_order = self.sort_order

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "parent_ids": parent_ids,
                "sort_order": sort_order,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        name = d.pop("name")

        parent_ids = cast(list[str], d.pop("parent_ids"))

        sort_order = d.pop("sort_order")

        object_ = cast(Literal["paper_category"] | Unset, d.pop("object", UNSET))
        if object_ != "paper_category" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'paper_category', got '{object_}'")

        post_v1_paper_categories_response_200 = cls(
            id=id,
            name=name,
            parent_ids=parent_ids,
            sort_order=sort_order,
            object_=object_,
        )

        post_v1_paper_categories_response_200.additional_properties = d
        return post_v1_paper_categories_response_200

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
