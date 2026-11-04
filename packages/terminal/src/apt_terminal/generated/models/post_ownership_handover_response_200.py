from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_ownership_handover_response_200_kind import PostOwnershipHandoverResponse200Kind
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_ownership_handover_response_200_moved_item import (
        PostOwnershipHandoverResponse200MovedItem,
    )


T = TypeVar("T", bound="PostOwnershipHandoverResponse200")


@_attrs_define
class PostOwnershipHandoverResponse200:
    """
    Attributes:
        kind (PostOwnershipHandoverResponse200Kind | Unset):
        from_ (str | Unset):
        to (str | Unset):
        moved (list[PostOwnershipHandoverResponse200MovedItem] | Unset):
    """

    kind: PostOwnershipHandoverResponse200Kind | Unset = UNSET
    from_: str | Unset = UNSET
    to: str | Unset = UNSET
    moved: list[PostOwnershipHandoverResponse200MovedItem] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kind: str | Unset = UNSET
        if not isinstance(self.kind, Unset):
            kind = self.kind.value

        from_ = self.from_

        to = self.to

        moved: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.moved, Unset):
            moved = []
            for moved_item_data in self.moved:
                moved_item = moved_item_data.to_dict()
                moved.append(moved_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if kind is not UNSET:
            field_dict["kind"] = kind
        if from_ is not UNSET:
            field_dict["from"] = from_
        if to is not UNSET:
            field_dict["to"] = to
        if moved is not UNSET:
            field_dict["moved"] = moved

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_ownership_handover_response_200_moved_item import (
            PostOwnershipHandoverResponse200MovedItem,
        )

        d = dict(src_dict)
        _kind = d.pop("kind", UNSET)
        kind: PostOwnershipHandoverResponse200Kind | Unset
        if isinstance(_kind, Unset):
            kind = UNSET
        else:
            kind = PostOwnershipHandoverResponse200Kind(_kind)

        from_ = d.pop("from", UNSET)

        to = d.pop("to", UNSET)

        _moved = d.pop("moved", UNSET)
        moved: list[PostOwnershipHandoverResponse200MovedItem] | Unset = UNSET
        if _moved is not UNSET:
            moved = []
            for moved_item_data in _moved:
                moved_item = PostOwnershipHandoverResponse200MovedItem.from_dict(moved_item_data)

                moved.append(moved_item)

        post_ownership_handover_response_200 = cls(
            kind=kind,
            from_=from_,
            to=to,
            moved=moved,
        )

        post_ownership_handover_response_200.additional_properties = d
        return post_ownership_handover_response_200

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
