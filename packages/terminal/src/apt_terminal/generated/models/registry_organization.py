from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="RegistryOrganization")


@_attrs_define
class RegistryOrganization:
    """
    Attributes:
        id (str):
        slug (str):
        name (str):
        description (None | str | Unset):
        rdid (str | Unset): org.<slug> — present on the POST create response; absent on plain GET/PATCH
    """

    id: str
    slug: str
    name: str
    description: None | str | Unset = UNSET
    rdid: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        slug = self.slug

        name = self.name

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        rdid = self.rdid

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "name": name,
            }
        )
        if description is not UNSET:
            field_dict["description"] = description
        if rdid is not UNSET:
            field_dict["rdid"] = rdid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        slug = d.pop("slug")

        name = d.pop("name")

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        rdid = d.pop("rdid", UNSET)

        registry_organization = cls(
            id=id,
            slug=slug,
            name=name,
            description=description,
            rdid=rdid,
        )

        registry_organization.additional_properties = d
        return registry_organization

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
