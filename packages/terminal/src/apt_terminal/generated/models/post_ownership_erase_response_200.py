from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_ownership_erase_response_200_kind import PostOwnershipEraseResponse200Kind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_ownership_erase_response_200_erased_item import (
        PostOwnershipEraseResponse200ErasedItem,
    )


T = TypeVar("T", bound="PostOwnershipEraseResponse200")


@_attrs_define
class PostOwnershipEraseResponse200:
    """
    Attributes:
        kind (PostOwnershipEraseResponse200Kind | Unset):
        id (str | Unset):
        erased (list[PostOwnershipEraseResponse200ErasedItem] | Unset):
    """

    kind: PostOwnershipEraseResponse200Kind | Unset = UNSET
    id: str | Unset = UNSET
    erased: list[PostOwnershipEraseResponse200ErasedItem] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
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
        if kind is not UNSET:
            field_dict["kind"] = kind
        if id is not UNSET:
            field_dict["id"] = id
        if erased is not UNSET:
            field_dict["erased"] = erased

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_ownership_erase_response_200_erased_item import (
            PostOwnershipEraseResponse200ErasedItem,
        )

        d = dict(src_dict)
        _kind = d.pop("kind", UNSET)
        kind: PostOwnershipEraseResponse200Kind | Unset
        if isinstance(_kind, Unset):
            kind = UNSET
        else:
            kind = PostOwnershipEraseResponse200Kind(_kind)

        id = d.pop("id", UNSET)

        _erased = d.pop("erased", UNSET)
        erased: list[PostOwnershipEraseResponse200ErasedItem] | Unset = UNSET
        if _erased is not UNSET:
            erased = []
            for erased_item_data in _erased:
                erased_item = PostOwnershipEraseResponse200ErasedItem.from_dict(erased_item_data)

                erased.append(erased_item)

        post_ownership_erase_response_200 = cls(
            kind=kind,
            id=id,
            erased=erased,
        )

        post_ownership_erase_response_200.additional_properties = d
        return post_ownership_erase_response_200

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
