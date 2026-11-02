from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.work_item_field_value_type import WorkItemFieldValueType
from ..types import UNSET, Unset

T = TypeVar("T", bound="WorkItemFieldValue")


@_attrs_define
class WorkItemFieldValue:
    """
    Attributes:
        field_id (str):
        key (str):
        label (str):
        type_ (WorkItemFieldValueType):
        value (Any | Unset): the field's stored value for this item (type matches the field's type); null when unset
    """

    field_id: str
    key: str
    label: str
    type_: WorkItemFieldValueType
    value: Any | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        field_id = self.field_id

        key = self.key

        label = self.label

        type_ = self.type_.value

        value = self.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "fieldId": field_id,
                "key": key,
                "label": label,
                "type": type_,
            }
        )
        if value is not UNSET:
            field_dict["value"] = value

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        field_id = d.pop("fieldId")

        key = d.pop("key")

        label = d.pop("label")

        type_ = WorkItemFieldValueType(d.pop("type"))

        value = d.pop("value", UNSET)

        work_item_field_value = cls(
            field_id=field_id,
            key=key,
            label=label,
            type_=type_,
            value=value,
        )

        work_item_field_value.additional_properties = d
        return work_item_field_value

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
