from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1OffersByOfferIdSetResponse200")


@_attrs_define
class PostV1OffersByOfferIdSetResponse200:
    """
    Attributes:
        offer_id (UUID):
        set_id (None | UUID):
        object_ (Literal['offer'] | Unset):
    """

    offer_id: UUID
    set_id: None | UUID
    object_: Literal["offer"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        offer_id = str(self.offer_id)

        set_id: None | str
        if isinstance(self.set_id, UUID):
            set_id = str(self.set_id)
        else:
            set_id = self.set_id

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "offer_id": offer_id,
                "set_id": set_id,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        offer_id = UUID(d.pop("offer_id"))

        def _parse_set_id(data: object) -> None | UUID:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                set_id_type_0 = UUID(data)

                return set_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | UUID, data)

        set_id = _parse_set_id(d.pop("set_id"))

        object_ = cast(Literal["offer"] | Unset, d.pop("object", UNSET))
        if object_ != "offer" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'offer', got '{object_}'")

        post_v1_offers_by_offer_id_set_response_200 = cls(
            offer_id=offer_id,
            set_id=set_id,
            object_=object_,
        )

        post_v1_offers_by_offer_id_set_response_200.additional_properties = d
        return post_v1_offers_by_offer_id_set_response_200

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
