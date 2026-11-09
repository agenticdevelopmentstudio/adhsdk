from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_customers_transfer_response_200_conflicts_item import (
        PostV1CustomersTransferResponse200ConflictsItem,
    )
    from ..models.post_v1_customers_transfer_response_200_moved import (
        PostV1CustomersTransferResponse200Moved,
    )


T = TypeVar("T", bound="PostV1CustomersTransferResponse200")


@_attrs_define
class PostV1CustomersTransferResponse200:
    """
    Attributes:
        object_ (Literal['customer'] | Unset):
        user_id (str | Unset):
        from_ (str | Unset):
        to (str | Unset):
        dry_run (bool | Unset):
        moved (PostV1CustomersTransferResponse200Moved | Unset):
        revoked (int | Unset): API tokens deleted
        ecosystems_reparented (int | Unset):
        rewritten (int | Unset): addresses re-derived by the cascade
        conflicts (list[PostV1CustomersTransferResponse200ConflictsItem] | Unset):
    """

    object_: Literal["customer"] | Unset = UNSET
    user_id: str | Unset = UNSET
    from_: str | Unset = UNSET
    to: str | Unset = UNSET
    dry_run: bool | Unset = UNSET
    moved: PostV1CustomersTransferResponse200Moved | Unset = UNSET
    revoked: int | Unset = UNSET
    ecosystems_reparented: int | Unset = UNSET
    rewritten: int | Unset = UNSET
    conflicts: list[PostV1CustomersTransferResponse200ConflictsItem] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        object_ = self.object_

        user_id = self.user_id

        from_ = self.from_

        to = self.to

        dry_run = self.dry_run

        moved: dict[str, Any] | Unset = UNSET
        if not isinstance(self.moved, Unset):
            moved = self.moved.to_dict()

        revoked = self.revoked

        ecosystems_reparented = self.ecosystems_reparented

        rewritten = self.rewritten

        conflicts: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.conflicts, Unset):
            conflicts = []
            for conflicts_item_data in self.conflicts:
                conflicts_item = conflicts_item_data.to_dict()
                conflicts.append(conflicts_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if object_ is not UNSET:
            field_dict["object"] = object_
        if user_id is not UNSET:
            field_dict["user_id"] = user_id
        if from_ is not UNSET:
            field_dict["from"] = from_
        if to is not UNSET:
            field_dict["to"] = to
        if dry_run is not UNSET:
            field_dict["dry_run"] = dry_run
        if moved is not UNSET:
            field_dict["moved"] = moved
        if revoked is not UNSET:
            field_dict["revoked"] = revoked
        if ecosystems_reparented is not UNSET:
            field_dict["ecosystems_reparented"] = ecosystems_reparented
        if rewritten is not UNSET:
            field_dict["rewritten"] = rewritten
        if conflicts is not UNSET:
            field_dict["conflicts"] = conflicts

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_customers_transfer_response_200_conflicts_item import (
            PostV1CustomersTransferResponse200ConflictsItem,
        )
        from ..models.post_v1_customers_transfer_response_200_moved import (
            PostV1CustomersTransferResponse200Moved,
        )

        d = dict(src_dict)
        object_ = cast(Literal["customer"] | Unset, d.pop("object", UNSET))
        if object_ != "customer" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'customer', got '{object_}'")

        user_id = d.pop("user_id", UNSET)

        from_ = d.pop("from", UNSET)

        to = d.pop("to", UNSET)

        dry_run = d.pop("dry_run", UNSET)

        _moved = d.pop("moved", UNSET)
        moved: PostV1CustomersTransferResponse200Moved | Unset
        if isinstance(_moved, Unset):
            moved = UNSET
        else:
            moved = PostV1CustomersTransferResponse200Moved.from_dict(_moved)

        revoked = d.pop("revoked", UNSET)

        ecosystems_reparented = d.pop("ecosystems_reparented", UNSET)

        rewritten = d.pop("rewritten", UNSET)

        _conflicts = d.pop("conflicts", UNSET)
        conflicts: list[PostV1CustomersTransferResponse200ConflictsItem] | Unset = UNSET
        if _conflicts is not UNSET:
            conflicts = []
            for conflicts_item_data in _conflicts:
                conflicts_item = PostV1CustomersTransferResponse200ConflictsItem.from_dict(
                    conflicts_item_data
                )

                conflicts.append(conflicts_item)

        post_v1_customers_transfer_response_200 = cls(
            object_=object_,
            user_id=user_id,
            from_=from_,
            to=to,
            dry_run=dry_run,
            moved=moved,
            revoked=revoked,
            ecosystems_reparented=ecosystems_reparented,
            rewritten=rewritten,
            conflicts=conflicts,
        )

        post_v1_customers_transfer_response_200.additional_properties = d
        return post_v1_customers_transfer_response_200

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
