from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.get_v1_ownership_transfers_preview_response_200_revoking_item import (
        GetV1OwnershipTransfersPreviewResponse200RevokingItem,
    )


T = TypeVar("T", bound="GetV1OwnershipTransfersPreviewResponse200")


@_attrs_define
class GetV1OwnershipTransfersPreviewResponse200:
    """
    Attributes:
        object_ (Literal['ownership.transfer'] | Unset):
        previous_id (None | str | Unset):
        tokens (int | Unset): API tokens the transfer would revoke
        revoking (list[GetV1OwnershipTransfersPreviewResponse200RevokingItem] | Unset): principals that lose reach over
            the object once it moves
    """

    object_: Literal["ownership.transfer"] | Unset = UNSET
    previous_id: None | str | Unset = UNSET
    tokens: int | Unset = UNSET
    revoking: list[GetV1OwnershipTransfersPreviewResponse200RevokingItem] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        object_ = self.object_

        previous_id: None | str | Unset
        if isinstance(self.previous_id, Unset):
            previous_id = UNSET
        else:
            previous_id = self.previous_id

        tokens = self.tokens

        revoking: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.revoking, Unset):
            revoking = []
            for revoking_item_data in self.revoking:
                revoking_item = revoking_item_data.to_dict()
                revoking.append(revoking_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if object_ is not UNSET:
            field_dict["object"] = object_
        if previous_id is not UNSET:
            field_dict["previous_id"] = previous_id
        if tokens is not UNSET:
            field_dict["tokens"] = tokens
        if revoking is not UNSET:
            field_dict["revoking"] = revoking

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_v1_ownership_transfers_preview_response_200_revoking_item import (
            GetV1OwnershipTransfersPreviewResponse200RevokingItem,
        )

        d = dict(src_dict)
        object_ = cast(Literal["ownership.transfer"] | Unset, d.pop("object", UNSET))
        if object_ != "ownership.transfer" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'ownership.transfer', got '{object_}'")

        def _parse_previous_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        previous_id = _parse_previous_id(d.pop("previous_id", UNSET))

        tokens = d.pop("tokens", UNSET)

        _revoking = d.pop("revoking", UNSET)
        revoking: list[GetV1OwnershipTransfersPreviewResponse200RevokingItem] | Unset = UNSET
        if _revoking is not UNSET:
            revoking = []
            for revoking_item_data in _revoking:
                revoking_item = GetV1OwnershipTransfersPreviewResponse200RevokingItem.from_dict(
                    revoking_item_data
                )

                revoking.append(revoking_item)

        get_v1_ownership_transfers_preview_response_200 = cls(
            object_=object_,
            previous_id=previous_id,
            tokens=tokens,
            revoking=revoking,
        )

        get_v1_ownership_transfers_preview_response_200.additional_properties = d
        return get_v1_ownership_transfers_preview_response_200

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
