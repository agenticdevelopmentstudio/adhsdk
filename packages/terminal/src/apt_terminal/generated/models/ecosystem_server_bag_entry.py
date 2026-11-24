from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="EcosystemServerBagEntry")


@_attrs_define
class EcosystemServerBagEntry:
    """
    Attributes:
        key (str):
        value (Any): Arbitrary JSON value
        description (str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
    """

    key: str
    value: Any
    description: str
    created: int
    updated: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        key = self.key

        value = self.value

        description = self.description

        created = self.created

        updated = self.updated

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "key": key,
                "value": value,
                "description": description,
                "created": created,
                "updated": updated,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        key = d.pop("key")

        value = d.pop("value")

        description = d.pop("description")

        created = d.pop("created")

        updated = d.pop("updated")

        ecosystem_server_bag_entry = cls(
            key=key,
            value=value,
            description=description,
            created=created,
            updated=updated,
        )

        ecosystem_server_bag_entry.additional_properties = d
        return ecosystem_server_bag_entry

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
