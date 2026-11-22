from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.set_effective_effective_type_0 import SetEffectiveEffectiveType0


T = TypeVar("T", bound="SetEffective")


@_attrs_define
class SetEffective:
    """
    Attributes:
        effective (None | SetEffectiveEffectiveType0): The customer's answer before the ecosystem's ceiling: null when
            the ecosystem has no sets; the held set ids, features and limits; or { error: 'unresolved' }.
    """

    effective: None | SetEffectiveEffectiveType0
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.set_effective_effective_type_0 import (
            SetEffectiveEffectiveType0,
        )

        effective: dict[str, Any] | None
        if isinstance(self.effective, SetEffectiveEffectiveType0):
            effective = self.effective.to_dict()
        else:
            effective = self.effective

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "effective": effective,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.set_effective_effective_type_0 import (
            SetEffectiveEffectiveType0,
        )

        d = dict(src_dict)

        def _parse_effective(data: object) -> None | SetEffectiveEffectiveType0:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                effective_type_0 = SetEffectiveEffectiveType0.from_dict(data)

                return effective_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | SetEffectiveEffectiveType0, data)

        effective = _parse_effective(d.pop("effective"))

        set_effective = cls(
            effective=effective,
        )

        set_effective.additional_properties = d
        return set_effective

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
