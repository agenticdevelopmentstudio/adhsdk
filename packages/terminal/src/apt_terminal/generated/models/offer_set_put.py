from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define

T = TypeVar("T", bound="OfferSetPut")


@_attrs_define
class OfferSetPut:
    """
    Attributes:
        set_id (None | UUID):
    """

    set_id: None | UUID

    def to_dict(self) -> dict[str, Any]:
        set_id: None | str
        if isinstance(self.set_id, UUID):
            set_id = str(self.set_id)
        else:
            set_id = self.set_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "set_id": set_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)

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

        offer_set_put = cls(
            set_id=set_id,
        )

        return offer_set_put
