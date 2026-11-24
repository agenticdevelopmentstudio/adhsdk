from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1RegistriesByIdSitemapResponse200")


@_attrs_define
class GetV1RegistriesByIdSitemapResponse200:
    """
    Attributes:
        slugs (list[str]): Public entry slugs, alphabetical.
        object_ (Literal['registry'] | Unset):
    """

    slugs: list[str]
    object_: Literal["registry"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slugs = self.slugs

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slugs": slugs,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slugs = cast(list[str], d.pop("slugs"))

        object_ = cast(Literal["registry"] | Unset, d.pop("object", UNSET))
        if object_ != "registry" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'registry', got '{object_}'")

        get_v1_registries_by_id_sitemap_response_200 = cls(
            slugs=slugs,
            object_=object_,
        )

        get_v1_registries_by_id_sitemap_response_200.additional_properties = d
        return get_v1_registries_by_id_sitemap_response_200

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
