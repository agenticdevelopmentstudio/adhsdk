from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.get_v1_ownership_transfers_preview_response_200_revoking_item_kind import (
    GetV1OwnershipTransfersPreviewResponse200RevokingItemKind,
)
from ..models.get_v1_ownership_transfers_preview_response_200_revoking_item_via import (
    GetV1OwnershipTransfersPreviewResponse200RevokingItemVia,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1OwnershipTransfersPreviewResponse200RevokingItem")


@_attrs_define
class GetV1OwnershipTransfersPreviewResponse200RevokingItem:
    """
    Attributes:
        kind (GetV1OwnershipTransfersPreviewResponse200RevokingItemKind | Unset):
        id (str | Unset):
        name (str | Unset):
        via (GetV1OwnershipTransfersPreviewResponse200RevokingItemVia | Unset): where the access came from
    """

    kind: GetV1OwnershipTransfersPreviewResponse200RevokingItemKind | Unset = UNSET
    id: str | Unset = UNSET
    name: str | Unset = UNSET
    via: GetV1OwnershipTransfersPreviewResponse200RevokingItemVia | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kind: str | Unset = UNSET
        if not isinstance(self.kind, Unset):
            kind = self.kind.value

        id = self.id

        name = self.name

        via: str | Unset = UNSET
        if not isinstance(self.via, Unset):
            via = self.via.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if kind is not UNSET:
            field_dict["kind"] = kind
        if id is not UNSET:
            field_dict["id"] = id
        if name is not UNSET:
            field_dict["name"] = name
        if via is not UNSET:
            field_dict["via"] = via

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        _kind = d.pop("kind", UNSET)
        kind: GetV1OwnershipTransfersPreviewResponse200RevokingItemKind | Unset
        if isinstance(_kind, Unset):
            kind = UNSET
        else:
            kind = GetV1OwnershipTransfersPreviewResponse200RevokingItemKind(_kind)

        id = d.pop("id", UNSET)

        name = d.pop("name", UNSET)

        _via = d.pop("via", UNSET)
        via: GetV1OwnershipTransfersPreviewResponse200RevokingItemVia | Unset
        if isinstance(_via, Unset):
            via = UNSET
        else:
            via = GetV1OwnershipTransfersPreviewResponse200RevokingItemVia(_via)

        get_v1_ownership_transfers_preview_response_200_revoking_item = cls(
            kind=kind,
            id=id,
            name=name,
            via=via,
        )

        get_v1_ownership_transfers_preview_response_200_revoking_item.additional_properties = d
        return get_v1_ownership_transfers_preview_response_200_revoking_item

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
