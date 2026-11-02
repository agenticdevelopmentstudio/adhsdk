from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostProjectWorkItemsIdDependenciesResponse201")


@_attrs_define
class PostProjectWorkItemsIdDependenciesResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        work_item_id (str): the dependent item (the path {id})
        depends_on_id (str): the work item it depends on
        created_at (str):
    """

    id: str
    ecosystem_id: str
    work_item_id: str
    depends_on_id: str
    created_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        work_item_id = self.work_item_id

        depends_on_id = self.depends_on_id

        created_at = self.created_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "workItemId": work_item_id,
                "dependsOnId": depends_on_id,
                "createdAt": created_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        work_item_id = d.pop("workItemId")

        depends_on_id = d.pop("dependsOnId")

        created_at = d.pop("createdAt")

        post_project_work_items_id_dependencies_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            work_item_id=work_item_id,
            depends_on_id=depends_on_id,
            created_at=created_at,
        )

        post_project_work_items_id_dependencies_response_201.additional_properties = d
        return post_project_work_items_id_dependencies_response_201

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
