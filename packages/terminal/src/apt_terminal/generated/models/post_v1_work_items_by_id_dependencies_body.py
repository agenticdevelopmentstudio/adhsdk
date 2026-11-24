from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostV1WorkItemsByIdDependenciesBody")


@_attrs_define
class PostV1WorkItemsByIdDependenciesBody:
    """
    Attributes:
        depends_on_id (str): a live work item in the same project (not self; must not close a cycle)
    """

    depends_on_id: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        depends_on_id = self.depends_on_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "depends_on_id": depends_on_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        depends_on_id = d.pop("depends_on_id")

        post_v1_work_items_by_id_dependencies_body = cls(
            depends_on_id=depends_on_id,
        )

        post_v1_work_items_by_id_dependencies_body.additional_properties = d
        return post_v1_work_items_by_id_dependencies_body

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
