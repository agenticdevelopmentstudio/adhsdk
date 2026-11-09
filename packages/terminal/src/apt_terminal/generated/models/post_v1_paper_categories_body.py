from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1PaperCategoriesBody")


@_attrs_define
class PostV1PaperCategoriesBody:
    """
    Attributes:
        name (str): The category name (unique per owner).
        parent_ids (list[str] | Unset): Ids of the categories this one sits under at creation — up to 8, or none. Omit
            or send [] for an unfiled category. This cap bounds validation cost on the create call only; a category can end
            up under any number of parents in total by adding further edges afterwards, via POST /content/category-edges.
    """

    name: str
    parent_ids: list[str] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        parent_ids: list[str] | Unset = UNSET
        if not isinstance(self.parent_ids, Unset):
            parent_ids = self.parent_ids

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
            }
        )
        if parent_ids is not UNSET:
            field_dict["parent_ids"] = parent_ids

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        parent_ids = cast(list[str], d.pop("parent_ids", UNSET))

        post_v1_paper_categories_body = cls(
            name=name,
            parent_ids=parent_ids,
        )

        post_v1_paper_categories_body.additional_properties = d
        return post_v1_paper_categories_body

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
