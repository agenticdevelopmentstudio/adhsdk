from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_ecosystem_namespaces_body_owner_kind import PostEcosystemNamespacesBodyOwnerKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostEcosystemNamespacesBody")


@_attrs_define
class PostEcosystemNamespacesBody:
    """
    Attributes:
        owner_kind (PostEcosystemNamespacesBodyOwnerKind):
        owner_id (str):
        rdid (str): Reverse-domain prefix
        slug (str | Unset):
        name (str | Unset):
    """

    owner_kind: PostEcosystemNamespacesBodyOwnerKind
    owner_id: str
    rdid: str
    slug: str | Unset = UNSET
    name: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        owner_kind = self.owner_kind.value

        owner_id = self.owner_id

        rdid = self.rdid

        slug = self.slug

        name = self.name

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "rdid": rdid,
            }
        )
        if slug is not UNSET:
            field_dict["slug"] = slug
        if name is not UNSET:
            field_dict["name"] = name

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        owner_kind = PostEcosystemNamespacesBodyOwnerKind(d.pop("ownerKind"))

        owner_id = d.pop("ownerId")

        rdid = d.pop("rdid")

        slug = d.pop("slug", UNSET)

        name = d.pop("name", UNSET)

        post_ecosystem_namespaces_body = cls(
            owner_kind=owner_kind,
            owner_id=owner_id,
            rdid=rdid,
            slug=slug,
            name=name,
        )

        post_ecosystem_namespaces_body.additional_properties = d
        return post_ecosystem_namespaces_body

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
