from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostRegistryRegistriesRegistryIdEntriesBodyValues")


@_attrs_define
class PostRegistryRegistriesRegistryIdEntriesBodyValues:
    """shape-checked against the live field defs on every write; required-ness only enforced when the resulting status is
    (or stays) published. On PATCH this is a JSON Merge Patch (RFC 7386) applied to the STORED values, not a full
    replace: a key you omit is left untouched; a key you send with a non-null value replaces that one field; a key you
    send as null DELETES it. Send only the section you are editing — the rest of the entry is preserved. On POST there
    is no prior state, so this object IS the initial values as given (null has no special meaning here).

    """

    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        post_registry_registries_registry_id_entries_body_values = cls()

        post_registry_registries_registry_id_entries_body_values.additional_properties = d
        return post_registry_registries_registry_id_entries_body_values

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
