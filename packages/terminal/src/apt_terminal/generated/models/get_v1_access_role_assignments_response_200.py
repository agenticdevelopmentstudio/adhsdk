from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.access_assignment import AccessAssignment


T = TypeVar("T", bound="GetV1AccessRoleAssignmentsResponse200")


@_attrs_define
class GetV1AccessRoleAssignmentsResponse200:
    """
    Attributes:
        assignments (list[AccessAssignment]):
        restricted (bool | Unset): present on item-scoped listings: whether the item is RESTRICTED
        object_ (Literal['access.role_assignment'] | Unset):
    """

    assignments: list[AccessAssignment]
    restricted: bool | Unset = UNSET
    object_: Literal["access.role_assignment"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        assignments = []
        for assignments_item_data in self.assignments:
            assignments_item = assignments_item_data.to_dict()
            assignments.append(assignments_item)

        restricted = self.restricted

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "assignments": assignments,
            }
        )
        if restricted is not UNSET:
            field_dict["restricted"] = restricted
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["access.role_assignment"] | Unset, d.pop("object", UNSET))
        if object_ != "access.role_assignment" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'access.role_assignment', got '{object_}'")

        get_v1_access_role_assignments_response_200 = cls(
            assignments=assignments,
            restricted=restricted,
            object_=object_,
        )

        get_v1_access_role_assignments_response_200.additional_properties = d
        return get_v1_access_role_assignments_response_200

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
