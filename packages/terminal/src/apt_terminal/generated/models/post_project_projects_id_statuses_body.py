from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_project_projects_id_statuses_body_category import (
    PostProjectProjectsIdStatusesBodyCategory,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostProjectProjectsIdStatusesBody")


@_attrs_define
class PostProjectProjectsIdStatusesBody:
    """
    Attributes:
        key (str):
        label (str):
        category (PostProjectProjectsIdStatusesBodyCategory):
        position (int | Unset): explicit column order; defaults to append (max+1)
    """

    key: str
    label: str
    category: PostProjectProjectsIdStatusesBodyCategory
    position: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        label = self.label

        category = self.category.value

        position = self.position

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "label": label,
                "category": category,
            }
        )
        if position is not UNSET:
            field_dict["position"] = position

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key")

        label = d.pop("label")

        category = PostProjectProjectsIdStatusesBodyCategory(d.pop("category"))

        position = d.pop("position", UNSET)

        post_project_projects_id_statuses_body = cls(
            key=key,
            label=label,
            category=category,
            position=position,
        )

        post_project_projects_id_statuses_body.additional_properties = d
        return post_project_projects_id_statuses_body

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
