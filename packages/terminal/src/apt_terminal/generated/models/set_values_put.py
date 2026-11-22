from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define

if TYPE_CHECKING:
    from ..models.set_value import SetValue


T = TypeVar("T", bound="SetValuesPut")


@_attrs_define
class SetValuesPut:
    """
    Attributes:
        values (list[SetValue]):
    """

    values: list[SetValue]

    def to_dict(self) -> dict[str, Any]:
        values = []
        for values_item_data in self.values:
            values_item = values_item_data.to_dict()
            values.append(values_item)

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "values": values,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.set_value import SetValue

        d = dict(src_dict)
        values = []
        _values = d.pop("values")
        for values_item_data in _values:
            values_item = SetValue.from_dict(values_item_data)

            values.append(values_item)

        set_values_put = cls(
            values=values,
        )

        return set_values_put
