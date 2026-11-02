from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.registry_field_def_show_if_type_0_op import RegistryFieldDefShowIfType0Op

T = TypeVar("T", bound="RegistryFieldDefShowIfType0")


@_attrs_define
class RegistryFieldDefShowIfType0:
    """a declarative visibility rule, evaluated fail-open (evaluateShowIf)

    Attributes:
        field (str): the key of the field this rule reads
        op (RegistryFieldDefShowIfType0Op):
        value (Any): JSON value compared against the referenced field (depth <= 8)
    """

    field: str
    op: RegistryFieldDefShowIfType0Op
    value: Any
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        field = self.field

        op = self.op.value

        value = self.value

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "field": field,
                "op": op,
                "value": value,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        field = d.pop("field")

        op = RegistryFieldDefShowIfType0Op(d.pop("op"))

        value = d.pop("value")

        registry_field_def_show_if_type_0 = cls(
            field=field,
            op=op,
            value=value,
        )

        registry_field_def_show_if_type_0.additional_properties = d
        return registry_field_def_show_if_type_0

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
