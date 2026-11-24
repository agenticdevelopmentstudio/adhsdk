from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.access_role_default_for import AccessRoleDefaultFor
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.access_grant import AccessGrant


T = TypeVar("T", bound="GetV1AccessRolesResponse200DataItem")


@_attrs_define
class GetV1AccessRolesResponse200DataItem:
    """
    Attributes:
        id (str):
        slug (str):
        name (str):
        description (str):
        is_system (bool):
        default_for (AccessRoleDefaultFor): which member kind holds this role implicitly as the workspace default
        grants (list[AccessGrant]):
        object_ (Literal['access.role'] | Unset):
    """

    id: str
    slug: str
    name: str
    description: str
    is_system: bool
    default_for: AccessRoleDefaultFor
    grants: list[AccessGrant]
    object_: Literal["access.role"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        slug = self.slug

        name = self.name

        description = self.description

        is_system = self.is_system

        default_for = self.default_for.value

        grants = []
        for grants_item_data in self.grants:
            grants_item = grants_item_data.to_dict()
            grants.append(grants_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "name": name,
                "description": description,
                "is_system": is_system,
                "default_for": default_for,
                "grants": grants,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.access_grant import AccessGrant

        d = dict(src_dict)
        id = d.pop("id")

        slug = d.pop("slug")

        name = d.pop("name")

        description = d.pop("description")

        is_system = d.pop("is_system")

        default_for = AccessRoleDefaultFor(d.pop("default_for"))

        grants = []
        _grants = d.pop("grants")
        for grants_item_data in _grants:
            grants_item = AccessGrant.from_dict(grants_item_data)

            grants.append(grants_item)

        object_ = cast(Literal["access.role"] | Unset, d.pop("object", UNSET))
        if object_ != "access.role" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'access.role', got '{object_}'")

        get_v1_access_roles_response_200_data_item = cls(
            id=id,
            slug=slug,
            name=name,
            description=description,
            is_system=is_system,
            default_for=default_for,
            grants=grants,
            object_=object_,
        )

        get_v1_access_roles_response_200_data_item.additional_properties = d
        return get_v1_access_roles_response_200_data_item

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
