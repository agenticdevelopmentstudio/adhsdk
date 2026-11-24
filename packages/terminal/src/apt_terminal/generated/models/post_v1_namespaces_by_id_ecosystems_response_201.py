from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1NamespacesByIdEcosystemsResponse201")


@_attrs_define
class PostV1NamespacesByIdEcosystemsResponse201:
    """
    Attributes:
        id (str):
        slug (str):
        rdid (str): ecosystem.<slug> for a root ecosystem, or ecosystem.<parent path>.<slug> for a child
        object_ (Literal['ecosystem'] | Unset):
    """

    id: str
    slug: str
    rdid: str
    object_: Literal["ecosystem"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        slug = self.slug

        rdid = self.rdid

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "rdid": rdid,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        slug = d.pop("slug")

        rdid = d.pop("rdid")

        object_ = cast(Literal["ecosystem"] | Unset, d.pop("object", UNSET))
        if object_ != "ecosystem" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'ecosystem', got '{object_}'")

        post_v1_namespaces_by_id_ecosystems_response_201 = cls(
            id=id,
            slug=slug,
            rdid=rdid,
            object_=object_,
        )

        post_v1_namespaces_by_id_ecosystems_response_201.additional_properties = d
        return post_v1_namespaces_by_id_ecosystems_response_201

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
