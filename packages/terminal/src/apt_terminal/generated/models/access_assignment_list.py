from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.access_assignment import AccessAssignment


T = TypeVar("T", bound="AccessAssignmentList")


@_attrs_define
class AccessAssignmentList:
    """
    Attributes:
        assignments (list[AccessAssignment]):
        restricted (bool | Unset): present on item-scoped listings: whether the item is RESTRICTED
    """

    assignments: list[AccessAssignment]
    restricted: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        assignments = []
        for assignments_item_data in self.assignments:
            assignments_item = assignments_item_data.to_dict()
            assignments.append(assignments_item)

        restricted = self.restricted

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "assignments": assignments,
            }
        )
        if restricted is not UNSET:
            field_dict["restricted"] = restricted

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.access_assignment import AccessAssignment

        d = dict(src_dict)
        assignments = []
        _assignments = d.pop("assignments")
        for assignments_item_data in _assignments:
            assignments_item = AccessAssignment.from_dict(assignments_item_data)

            assignments.append(assignments_item)

        restricted = d.pop("restricted", UNSET)

        access_assignment_list = cls(
            assignments=assignments,
            restricted=restricted,
        )

        access_assignment_list.additional_properties = d
        return access_assignment_list

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
