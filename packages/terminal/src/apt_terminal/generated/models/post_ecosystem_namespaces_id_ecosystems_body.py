from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostEcosystemNamespacesIdEcosystemsBody")


@_attrs_define
class PostEcosystemNamespacesIdEcosystemsBody:
    """
    Attributes:
        slug (str):
        name (str):
        rdid (str | Unset): Override; defaults to <namespace-prefix>.<slug>
    """

    slug: str
    name: str
    rdid: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        slug = self.slug

        name = self.name

        rdid = self.rdid

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "slug": slug,
                "name": name,
            }
        )
        if rdid is not UNSET:
            field_dict["rdid"] = rdid

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        slug = d.pop("slug")

        name = d.pop("name")

        rdid = d.pop("rdid", UNSET)

        post_ecosystem_namespaces_id_ecosystems_body = cls(
            slug=slug,
            name=name,
            rdid=rdid,
        )

        post_ecosystem_namespaces_id_ecosystems_body.additional_properties = d
        return post_ecosystem_namespaces_id_ecosystems_body

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
