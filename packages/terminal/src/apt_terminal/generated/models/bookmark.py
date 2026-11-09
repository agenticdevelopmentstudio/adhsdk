from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="Bookmark")


@_attrs_define
class Bookmark:
    """
    Attributes:
        id (str):
        customer_id (str): The customer who owns the bookmark, or '' when the owner is not a customer. Kept for clients
            built before the pairs; read ownerKind/ownerId instead.
        owner_kind (str): Kind of principal that owns the bookmark: 'customer', 'organization', 'application', 'persona'
            or 'ecosystem'.
        owner_id (str): Id of the owning principal.
        ecosystem_id (str):
        target_kind (str):
        target_id (str):
        notify (bool):
        created_at (str):
        deleted_at (None | str | Unset):
    """

    id: str
    customer_id: str
    owner_kind: str
    owner_id: str
    ecosystem_id: str
    target_kind: str
    target_id: str
    notify: bool
    created_at: str
    deleted_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        customer_id = self.customer_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        ecosystem_id = self.ecosystem_id

        target_kind = self.target_kind

        target_id = self.target_id

        notify = self.notify

        created_at = self.created_at

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "customerId": customer_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "ecosystemId": ecosystem_id,
                "targetKind": target_kind,
                "targetId": target_id,
                "notify": notify,
                "createdAt": created_at,
            }
        )
        if deleted_at is not UNSET:
            field_dict["deletedAt"] = deleted_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        customer_id = d.pop("customerId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        ecosystem_id = d.pop("ecosystemId")

        target_kind = d.pop("targetKind")

        target_id = d.pop("targetId")

        notify = d.pop("notify")

        created_at = d.pop("createdAt")

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt", UNSET))

        bookmark = cls(
            id=id,
            customer_id=customer_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            ecosystem_id=ecosystem_id,
            target_kind=target_kind,
            target_id=target_id,
            notify=notify,
            created_at=created_at,
            deleted_at=deleted_at,
        )

        bookmark.additional_properties = d
        return bookmark

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
