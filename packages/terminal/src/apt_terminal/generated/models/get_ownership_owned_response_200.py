from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_ownership_owned_response_200_kind import GetOwnershipOwnedResponse200Kind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.get_ownership_owned_response_200_owned_item import (
        GetOwnershipOwnedResponse200OwnedItem,
    )


T = TypeVar("T", bound="GetOwnershipOwnedResponse200")


@_attrs_define
class GetOwnershipOwnedResponse200:
    """
    Attributes:
        kind (GetOwnershipOwnedResponse200Kind | Unset):
        id (str | Unset):
        owned (list[GetOwnershipOwnedResponse200OwnedItem] | Unset):
    """

    kind: GetOwnershipOwnedResponse200Kind | Unset = UNSET
    id: str | Unset = UNSET
    owned: list[GetOwnershipOwnedResponse200OwnedItem] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
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
        if kind is not UNSET:
            field_dict["kind"] = kind
        if id is not UNSET:
            field_dict["id"] = id
        if owned is not UNSET:
            field_dict["owned"] = owned

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_ownership_owned_response_200_owned_item import (
            GetOwnershipOwnedResponse200OwnedItem,
        )

        d = dict(src_dict)
        _kind = d.pop("kind", UNSET)
        kind: GetOwnershipOwnedResponse200Kind | Unset
        if isinstance(_kind, Unset):
            kind = UNSET
        else:
            kind = GetOwnershipOwnedResponse200Kind(_kind)

        id = d.pop("id", UNSET)

        _owned = d.pop("owned", UNSET)
        owned: list[GetOwnershipOwnedResponse200OwnedItem] | Unset = UNSET
        if _owned is not UNSET:
            owned = []
            for owned_item_data in _owned:
                owned_item = GetOwnershipOwnedResponse200OwnedItem.from_dict(owned_item_data)

                owned.append(owned_item)

        get_ownership_owned_response_200 = cls(
            kind=kind,
            id=id,
            owned=owned,
        )

        get_ownership_owned_response_200.additional_properties = d
        return get_ownership_owned_response_200

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
