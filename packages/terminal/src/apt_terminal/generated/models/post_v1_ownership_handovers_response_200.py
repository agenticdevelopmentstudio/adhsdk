from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_ownership_handovers_response_200_kind import (
    PostV1OwnershipHandoversResponse200Kind,
)
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_ownership_handovers_response_200_moved_item import (
        PostV1OwnershipHandoversResponse200MovedItem,
    )


T = TypeVar("T", bound="PostV1OwnershipHandoversResponse200")


@_attrs_define
class PostV1OwnershipHandoversResponse200:
    """
    Attributes:
        object_ (Literal['ownership.handover'] | Unset):
        kind (PostV1OwnershipHandoversResponse200Kind | Unset):
        from_ (str | Unset):
        to (str | Unset):
        moved (list[PostV1OwnershipHandoversResponse200MovedItem] | Unset):
    """

    object_: Literal["ownership.handover"] | Unset = UNSET
    kind: PostV1OwnershipHandoversResponse200Kind | Unset = UNSET
    from_: str | Unset = UNSET
    to: str | Unset = UNSET
    moved: list[PostV1OwnershipHandoversResponse200MovedItem] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        object_ = self.object_

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
        if object_ is not UNSET:
            field_dict["object"] = object_
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
        from ..models.post_v1_ownership_handovers_response_200_moved_item import (
            PostV1OwnershipHandoversResponse200MovedItem,
        )

        d = dict(src_dict)
        object_ = cast(Literal["ownership.handover"] | Unset, d.pop("object", UNSET))
        if object_ != "ownership.handover" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'ownership.handover', got '{object_}'")

        _kind = d.pop("kind", UNSET)
        kind: PostV1OwnershipHandoversResponse200Kind | Unset
        if isinstance(_kind, Unset):
            kind = UNSET
        else:
            kind = PostV1OwnershipHandoversResponse200Kind(_kind)

        from_ = d.pop("from", UNSET)

        to = d.pop("to", UNSET)

        _moved = d.pop("moved", UNSET)
        moved: list[PostV1OwnershipHandoversResponse200MovedItem] | Unset = UNSET
        if _moved is not UNSET:
            moved = []
            for moved_item_data in _moved:
                moved_item = PostV1OwnershipHandoversResponse200MovedItem.from_dict(moved_item_data)

                moved.append(moved_item)

        post_v1_ownership_handovers_response_200 = cls(
            object_=object_,
            kind=kind,
            from_=from_,
            to=to,
            moved=moved,
        )

        post_v1_ownership_handovers_response_200.additional_properties = d
        return post_v1_ownership_handovers_response_200

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
