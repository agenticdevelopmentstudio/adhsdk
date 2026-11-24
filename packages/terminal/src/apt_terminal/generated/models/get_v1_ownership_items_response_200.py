from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_v1_ownership_items_response_200_kind import GetV1OwnershipItemsResponse200Kind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.get_v1_ownership_items_response_200_owned_item import (
        GetV1OwnershipItemsResponse200OwnedItem,
    )


T = TypeVar("T", bound="GetV1OwnershipItemsResponse200")


@_attrs_define
class GetV1OwnershipItemsResponse200:
    """
    Attributes:
        object_ (Literal['ownership.item'] | Unset):
        kind (GetV1OwnershipItemsResponse200Kind | Unset):
        id (str | Unset):
        owned (list[GetV1OwnershipItemsResponse200OwnedItem] | Unset):
    """

    object_: Literal["ownership.item"] | Unset = UNSET
    kind: GetV1OwnershipItemsResponse200Kind | Unset = UNSET
    id: str | Unset = UNSET
    owned: list[GetV1OwnershipItemsResponse200OwnedItem] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        object_ = self.object_

        kind: str | Unset = UNSET
        if not isinstance(self.kind, Unset):
            kind = self.kind.value

        id = self.id

        owned: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.owned, Unset):
            owned = []
            for owned_item_data in self.owned:
                owned_item = owned_item_data.to_dict()
                owned.append(owned_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if object_ is not UNSET:
            field_dict["object"] = object_
        if kind is not UNSET:
            field_dict["kind"] = kind
        if id is not UNSET:
            field_dict["id"] = id
        if owned is not UNSET:
            field_dict["owned"] = owned

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_v1_ownership_items_response_200_owned_item import (
            GetV1OwnershipItemsResponse200OwnedItem,
        )

        d = dict(src_dict)
        object_ = cast(Literal["ownership.item"] | Unset, d.pop("object", UNSET))
        if object_ != "ownership.item" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'ownership.item', got '{object_}'")

        _kind = d.pop("kind", UNSET)
        kind: GetV1OwnershipItemsResponse200Kind | Unset
        if isinstance(_kind, Unset):
            kind = UNSET
        else:
            kind = GetV1OwnershipItemsResponse200Kind(_kind)

        id = d.pop("id", UNSET)

        _owned = d.pop("owned", UNSET)
        owned: list[GetV1OwnershipItemsResponse200OwnedItem] | Unset = UNSET
        if _owned is not UNSET:
            owned = []
            for owned_item_data in _owned:
                owned_item = GetV1OwnershipItemsResponse200OwnedItem.from_dict(owned_item_data)

                owned.append(owned_item)

        get_v1_ownership_items_response_200 = cls(
            object_=object_,
            kind=kind,
            id=id,
            owned=owned,
        )

        get_v1_ownership_items_response_200.additional_properties = d
        return get_v1_ownership_items_response_200

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
