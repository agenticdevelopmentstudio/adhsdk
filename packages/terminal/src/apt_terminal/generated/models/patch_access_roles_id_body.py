from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.patch_access_roles_id_body_default_for import PatchAccessRolesIdBodyDefaultFor
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.access_grant import AccessGrant


T = TypeVar("T", bound="PatchAccessRolesIdBody")


@_attrs_define
class PatchAccessRolesIdBody:
    """
    Attributes:
        name (str | Unset):
        description (str | Unset):
        default_for (PatchAccessRolesIdBodyDefaultFor | Unset):
        grants (list[AccessGrant] | Unset):
    """

    name: str | Unset = UNSET
    description: str | Unset = UNSET
    default_for: PatchAccessRolesIdBodyDefaultFor | Unset = UNSET
    grants: list[AccessGrant] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        description = self.description

        default_for: str | Unset = UNSET
        if not isinstance(self.default_for, Unset):
            default_for = self.default_for.value

        grants: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.grants, Unset):
            grants = []
            for grants_item_data in self.grants:
                grants_item = grants_item_data.to_dict()
                grants.append(grants_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if name is not UNSET:
            field_dict["name"] = name
        if description is not UNSET:
            field_dict["description"] = description
        if default_for is not UNSET:
            field_dict["defaultFor"] = default_for
        if grants is not UNSET:
            field_dict["grants"] = grants

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.access_grant import AccessGrant

        d = dict(src_dict)
        name = d.pop("name", UNSET)

        description = d.pop("description", UNSET)

        _default_for = d.pop("defaultFor", UNSET)
        default_for: PatchAccessRolesIdBodyDefaultFor | Unset
        if isinstance(_default_for, Unset):
            default_for = UNSET
        else:
            default_for = PatchAccessRolesIdBodyDefaultFor(_default_for)

        _grants = d.pop("grants", UNSET)
        grants: list[AccessGrant] | Unset = UNSET
        if _grants is not UNSET:
            grants = []
            for grants_item_data in _grants:
                grants_item = AccessGrant.from_dict(grants_item_data)

                grants.append(grants_item)

        patch_access_roles_id_body = cls(
            name=name,
            description=description,
            default_for=default_for,
            grants=grants,
        )

        patch_access_roles_id_body.additional_properties = d
        return patch_access_roles_id_body

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
