from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.put_project_work_items_id_fields_body_values_item import (
        PutProjectWorkItemsIdFieldsBodyValuesItem,
    )


T = TypeVar("T", bound="PutProjectWorkItemsIdFieldsBody")


@_attrs_define
class PutProjectWorkItemsIdFieldsBody:
    """
    Attributes:
        values (list[PutProjectWorkItemsIdFieldsBodyValuesItem]): a batch of set/clear operations, applied in payload
            order; ALL entries are validated before any write, so a bad entry fails the whole batch. An empty array is a
            legal no-op.
    """

    values: list[PutProjectWorkItemsIdFieldsBodyValuesItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        values = []
        for values_item_data in self.values:
            values_item = values_item_data.to_dict()
            values.append(values_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "values": values,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.put_project_work_items_id_fields_body_values_item import (
            PutProjectWorkItemsIdFieldsBodyValuesItem,
        )

        d = dict(src_dict)
        values = []
        _values = d.pop("values")
        for values_item_data in _values:
            values_item = PutProjectWorkItemsIdFieldsBodyValuesItem.from_dict(values_item_data)

            values.append(values_item)

        put_project_work_items_id_fields_body = cls(
            values=values,
        )

        put_project_work_items_id_fields_body.additional_properties = d
        return put_project_work_items_id_fields_body

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
