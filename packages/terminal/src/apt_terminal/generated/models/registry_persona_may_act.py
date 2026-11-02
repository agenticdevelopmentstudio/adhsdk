from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.registry_persona_may_act_kinds_item import RegistryPersonaMayActKindsItem

T = TypeVar("T", bound="RegistryPersonaMayAct")


@_attrs_define
class RegistryPersonaMayAct:
    """
    Attributes:
        kinds (list[RegistryPersonaMayActKindsItem]): the subject kinds this persona may act for (always includes
            'self')
    """

    kinds: list[RegistryPersonaMayActKindsItem]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kinds = []
        for kinds_item_data in self.kinds:
            kinds_item = kinds_item_data.value
            kinds.append(kinds_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "kinds": kinds,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        kinds = []
        _kinds = d.pop("kinds")
        for kinds_item_data in _kinds:
            kinds_item = RegistryPersonaMayActKindsItem(kinds_item_data)

            kinds.append(kinds_item)

        registry_persona_may_act = cls(
            kinds=kinds,
        )

        registry_persona_may_act.additional_properties = d
        return registry_persona_may_act

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
