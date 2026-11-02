from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.access_role import AccessRole


T = TypeVar("T", bound="AccessRoleList")


@_attrs_define
class AccessRoleList:
    """
    Attributes:
        roles (list[AccessRole]):
    """

    roles: list[AccessRole]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        roles = []
        for roles_item_data in self.roles:
            roles_item = roles_item_data.to_dict()
            roles.append(roles_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "roles": roles,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.access_role import AccessRole

        d = dict(src_dict)
        roles = []
        _roles = d.pop("roles")
        for roles_item_data in _roles:
            roles_item = AccessRole.from_dict(roles_item_data)

            roles.append(roles_item)

        access_role_list = cls(
            roles=roles,
        )

        access_role_list.additional_properties = d
        return access_role_list

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
