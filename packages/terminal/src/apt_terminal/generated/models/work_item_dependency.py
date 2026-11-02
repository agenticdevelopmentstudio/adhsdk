from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="WorkItemDependency")


@_attrs_define
class WorkItemDependency:
    """
    Attributes:
        id (str): the dependency edge id
        depends_on_id (str): the work item this one depends on
        title (str): the depended-on item title (joined)
        status (str): the depended-on item statusId (joined)
        created_at (str):
    """

    id: str
    depends_on_id: str
    title: str
    status: str
    created_at: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        depends_on_id = self.depends_on_id

        title = self.title

        status = self.status

        created_at = self.created_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "dependsOnId": depends_on_id,
                "title": title,
                "status": status,
                "createdAt": created_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        depends_on_id = d.pop("dependsOnId")

        title = d.pop("title")

        status = d.pop("status")

        created_at = d.pop("createdAt")

        work_item_dependency = cls(
            id=id,
            depends_on_id=depends_on_id,
            title=title,
            status=status,
            created_at=created_at,
        )

        work_item_dependency.additional_properties = d
        return work_item_dependency

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
