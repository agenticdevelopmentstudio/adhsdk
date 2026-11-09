from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostV1WorkItemsByIdBodyFieldsValuesItem")


@_attrs_define
class PostV1WorkItemsByIdBodyFieldsValuesItem:
    """
    Attributes:
        field_id (str):
        value (Any): the value to store (must match the field's type), or null to clear it
    """

    field_id: str
    value: Any
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        field_id = self.field_id

        value = self.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "field_id": field_id,
                "value": value,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        field_id = d.pop("field_id")

        value = d.pop("value")

        post_v1_work_items_by_id_body_fields_values_item = cls(
            field_id=field_id,
            value=value,
        )

        post_v1_work_items_by_id_body_fields_values_item.additional_properties = d
        return post_v1_work_items_by_id_body_fields_values_item

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
