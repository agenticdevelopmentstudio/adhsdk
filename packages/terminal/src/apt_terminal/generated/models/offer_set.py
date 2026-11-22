from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="OfferSet")


@_attrs_define
class OfferSet:
    """
    Attributes:
        offer_id (UUID):
        set_id (None | UUID):
    """

    offer_id: UUID
    set_id: None | UUID
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        offer_id = str(self.offer_id)

        set_id: None | str
        if isinstance(self.set_id, UUID):
            set_id = str(self.set_id)
        else:
            set_id = self.set_id

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "offer_id": offer_id,
                "set_id": set_id,
            }
        )

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

        offer_set = cls(
            offer_id=offer_id,
            set_id=set_id,
        )

        offer_set.additional_properties = d
        return offer_set

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
