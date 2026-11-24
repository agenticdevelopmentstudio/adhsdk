from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_ownership_erasures_response_200_kind import (
    PostV1OwnershipErasuresResponse200Kind,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_ownership_erasures_response_200_erased_item import (
        PostV1OwnershipErasuresResponse200ErasedItem,
    )


T = TypeVar("T", bound="PostV1OwnershipErasuresResponse200")


@_attrs_define
class PostV1OwnershipErasuresResponse200:
    """
    Attributes:
        object_ (Literal['ownership.erasure'] | Unset):
        kind (PostV1OwnershipErasuresResponse200Kind | Unset):
        id (str | Unset):
        erased (list[PostV1OwnershipErasuresResponse200ErasedItem] | Unset):
    """

    object_: Literal["ownership.erasure"] | Unset = UNSET
    kind: PostV1OwnershipErasuresResponse200Kind | Unset = UNSET
    id: str | Unset = UNSET
    erased: list[PostV1OwnershipErasuresResponse200ErasedItem] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        object_ = self.object_

        kind: str | Unset = UNSET
        if not isinstance(self.kind, Unset):
            kind = self.kind.value

        id = self.id

        erased: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.erased, Unset):
            erased = []
            for erased_item_data in self.erased:
                erased_item = erased_item_data.to_dict()
                erased.append(erased_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if object_ is not UNSET:
            field_dict["object"] = object_
        if kind is not UNSET:
            field_dict["kind"] = kind
        if id is not UNSET:
            field_dict["id"] = id
        if erased is not UNSET:
            field_dict["erased"] = erased

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_ownership_erasures_response_200_erased_item import (
            PostV1OwnershipErasuresResponse200ErasedItem,
        )

        d = dict(src_dict)
        object_ = cast(Literal["ownership.erasure"] | Unset, d.pop("object", UNSET))
        if object_ != "ownership.erasure" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'ownership.erasure', got '{object_}'")

        _kind = d.pop("kind", UNSET)
        kind: PostV1OwnershipErasuresResponse200Kind | Unset
        if isinstance(_kind, Unset):
            kind = UNSET
        else:
            kind = PostV1OwnershipErasuresResponse200Kind(_kind)

        id = d.pop("id", UNSET)

        _erased = d.pop("erased", UNSET)
        erased: list[PostV1OwnershipErasuresResponse200ErasedItem] | Unset = UNSET
        if _erased is not UNSET:
            erased = []
            for erased_item_data in _erased:
                erased_item = PostV1OwnershipErasuresResponse200ErasedItem.from_dict(
                    erased_item_data
                )

                erased.append(erased_item)

        post_v1_ownership_erasures_response_200 = cls(
            object_=object_,
            kind=kind,
            id=id,
            erased=erased,
        )

        post_v1_ownership_erasures_response_200.additional_properties = d
        return post_v1_ownership_erasures_response_200

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
