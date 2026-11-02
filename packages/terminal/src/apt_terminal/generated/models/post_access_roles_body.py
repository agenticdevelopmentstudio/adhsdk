from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_access_roles_body_default_for import PostAccessRolesBodyDefaultFor
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.access_grant import AccessGrant


T = TypeVar("T", bound="PostAccessRolesBody")


@_attrs_define
class PostAccessRolesBody:
    """
    Attributes:
        slug (str):
        name (str):
        grants (list[AccessGrant]):
        description (str | Unset):
        default_for (PostAccessRolesBodyDefaultFor | Unset):
    """

    slug: str
    name: str
    grants: list[AccessGrant]
    description: str | Unset = UNSET
    default_for: PostAccessRolesBodyDefaultFor | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        grants = []
        for grants_item_data in self.grants:
            grants_item = grants_item_data.to_dict()
            grants.append(grants_item)

        description = self.description

        default_for: str | Unset = UNSET
        if not isinstance(self.default_for, Unset):
            default_for = self.default_for.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "name": name,
                "grants": grants,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if default_for is not UNSET:
            field_dict["defaultFor"] = default_for

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.access_grant import AccessGrant

        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        grants = []
        _grants = d.pop("grants")
        for grants_item_data in _grants:
            grants_item = AccessGrant.from_dict(grants_item_data)

            grants.append(grants_item)

        description = d.pop("description", UNSET)

        _default_for = d.pop("defaultFor", UNSET)
        default_for: PostAccessRolesBodyDefaultFor | Unset
        if isinstance(_default_for, Unset):
            default_for = UNSET
        else:
            default_for = PostAccessRolesBodyDefaultFor(_default_for)

        post_access_roles_body = cls(
            slug=slug,
            name=name,
            grants=grants,
            description=description,
            default_for=default_for,
        )

        post_access_roles_body.additional_properties = d
        return post_access_roles_body

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
