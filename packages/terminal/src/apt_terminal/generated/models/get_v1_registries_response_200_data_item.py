from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1RegistriesResponse200DataItem")


@_attrs_define
class GetV1RegistriesResponse200DataItem:
    """
    Attributes:
        slug (str):
        name (str):
        purpose (str): One-line "what this registry is for".
        category_root (str): The industry half of <industry>.<service-type>, e.g. 'software'.
        tags (list[str]): The owner's discovery labels.
        object_ (Literal['registry'] | Unset):
    """

    slug: str
    name: str
    purpose: str
    category_root: str
    tags: list[str]
    object_: Literal["registry"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        purpose = self.purpose

        category_root = self.category_root

        tags = self.tags

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "name": name,
                "purpose": purpose,
                "category_root": category_root,
                "tags": tags,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        purpose = d.pop("purpose")

        category_root = d.pop("category_root")

        tags = cast(list[str], d.pop("tags"))

        object_ = cast(Literal["registry"] | Unset, d.pop("object", UNSET))
        if object_ != "registry" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'registry', got '{object_}'")

        get_v1_registries_response_200_data_item = cls(
            slug=slug,
            name=name,
            purpose=purpose,
            category_root=category_root,
            tags=tags,
            object_=object_,
        )

        get_v1_registries_response_200_data_item.additional_properties = d
        return get_v1_registries_response_200_data_item

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
