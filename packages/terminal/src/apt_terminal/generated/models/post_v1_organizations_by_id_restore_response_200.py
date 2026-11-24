from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1OrganizationsByIdRestoreResponse200")


@_attrs_define
class PostV1OrganizationsByIdRestoreResponse200:
    """
    Attributes:
        id (str):
        slug (str):
        name (str):
        description (None | str | Unset):
        rdid (str | Unset): org.<slug> — present on the POST create response; absent on plain GET/PATCH
        object_ (Literal['organization'] | Unset):
    """

    id: str
    slug: str
    name: str
    description: None | str | Unset = UNSET
    rdid: str | Unset = UNSET
    object_: Literal["organization"] | Unset = UNSET
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

        object_ = self.object_

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
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["organization"] | Unset, d.pop("object", UNSET))
        if object_ != "organization" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'organization', got '{object_}'")

        post_v1_organizations_by_id_restore_response_200 = cls(
            id=id,
            slug=slug,
            name=name,
            description=description,
            rdid=rdid,
            object_=object_,
        )

        post_v1_organizations_by_id_restore_response_200.additional_properties = d
        return post_v1_organizations_by_id_restore_response_200

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
