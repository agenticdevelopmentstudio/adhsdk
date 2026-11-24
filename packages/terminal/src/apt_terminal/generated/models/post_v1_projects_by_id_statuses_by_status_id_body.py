from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_projects_by_id_statuses_by_status_id_body_category import (
    PostV1ProjectsByIdStatusesByStatusIdBodyCategory,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProjectsByIdStatusesByStatusIdBody")


@_attrs_define
class PostV1ProjectsByIdStatusesByStatusIdBody:
    """
    Attributes:
        label (str | Unset):
        category (PostV1ProjectsByIdStatusesByStatusIdBodyCategory | Unset):
        position (int | Unset):
    """

    label: str | Unset = UNSET
    category: PostV1ProjectsByIdStatusesByStatusIdBodyCategory | Unset = UNSET
    position: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        label = self.label

        category: str | Unset = UNSET
        if not isinstance(self.category, Unset):
            category = self.category.value

        position = self.position

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if label is not UNSET:
            field_dict["label"] = label
        if category is not UNSET:
            field_dict["category"] = category
        if position is not UNSET:
            field_dict["position"] = position

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        label = d.pop("label", UNSET)

        _category = d.pop("category", UNSET)
        category: PostV1ProjectsByIdStatusesByStatusIdBodyCategory | Unset
        if isinstance(_category, Unset):
            category = UNSET
        else:
            category = PostV1ProjectsByIdStatusesByStatusIdBodyCategory(_category)

        position = d.pop("position", UNSET)

        post_v1_projects_by_id_statuses_by_status_id_body = cls(
            label=label,
            category=category,
            position=position,
        )

        post_v1_projects_by_id_statuses_by_status_id_body.additional_properties = d
        return post_v1_projects_by_id_statuses_by_status_id_body

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
