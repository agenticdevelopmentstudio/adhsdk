from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.registry_namespace_owner_kind import RegistryNamespaceOwnerKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1NamespacesResponse201")


@_attrs_define
class PostV1NamespacesResponse201:
    """
    Attributes:
        id (str):
        owner_kind (RegistryNamespaceOwnerKind):
        owner_id (str):
        slug (None | str):
        name (None | str):
        rdid (None | str): Always null for a namespace created after Task 5 (rdid-addressing-model); non-null only on
            rows minted before it
        object_ (Literal['namespace'] | Unset):
    """

    id: str
    owner_kind: RegistryNamespaceOwnerKind
    owner_id: str
    slug: None | str
    name: None | str
    rdid: None | str
    object_: Literal["namespace"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        owner_kind = self.owner_kind.value

        owner_id = self.owner_id

        slug: None | str
        slug = self.slug

        name: None | str
        name = self.name

        rdid: None | str
        rdid = self.rdid

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "slug": slug,
                "name": name,
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

        owner_kind = RegistryNamespaceOwnerKind(d.pop("owner_kind"))

        owner_id = d.pop("owner_id")

        def _parse_slug(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        slug = _parse_slug(d.pop("slug"))

        def _parse_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        name = _parse_name(d.pop("name"))

        def _parse_rdid(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        rdid = _parse_rdid(d.pop("rdid"))

        object_ = cast(Literal["namespace"] | Unset, d.pop("object", UNSET))
        if object_ != "namespace" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'namespace', got '{object_}'")

        post_v1_namespaces_response_201 = cls(
            id=id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            slug=slug,
            name=name,
            rdid=rdid,
            object_=object_,
        )

        post_v1_namespaces_response_201.additional_properties = d
        return post_v1_namespaces_response_201

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
