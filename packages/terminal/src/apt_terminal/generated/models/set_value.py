from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..models.set_value_kind import SetValueKind

T = TypeVar("T", bound="SetValue")


@_attrs_define
class SetValue:
    """
    Attributes:
        kind (SetValueKind):
        key (str): A feature key for a permission, a limit key (e.g. `usage.tier`) for a limit; both from the catalog's
            `setEntries`.
        value (Any): true for a permission; for a limit, a tier slug (string) or a byte or count (integer).
    """

    kind: SetValueKind
    key: str
    value: Any

    def to_dict(self) -> dict[str, Any]:
        kind = self.kind.value

        key = self.key

        value = self.value

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "kind": kind,
                "key": key,
                "value": value,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        kind = SetValueKind(d.pop("kind"))

        key = d.pop("key")

        value = d.pop("value")

        set_value = cls(
            kind=kind,
            key=key,
            value=value,
        )

        return set_value
