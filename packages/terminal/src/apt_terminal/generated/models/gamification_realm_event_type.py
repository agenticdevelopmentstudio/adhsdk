from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GamificationRealmEventType")


@_attrs_define
class GamificationRealmEventType:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        name (str): The custom event_type key
        stat_key (str): The gamification stat this event bumps
        created (int | Unset): Unix timestamp, in seconds.
        updated (int | Unset): Unix timestamp, in seconds.
    """

    id: str
    ecosystem_id: str
    name: str
    stat_key: str
    created: int | Unset = UNSET
    updated: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        name = self.name

        stat_key = self.stat_key

        created = self.created

        updated = self.updated

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "name": name,
                "stat_key": stat_key,
            }
        )
        if created is not UNSET:
            field_dict["created"] = created
        if updated is not UNSET:
            field_dict["updated"] = updated

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        name = d.pop("name")

        stat_key = d.pop("stat_key")

        created = d.pop("created", UNSET)

        updated = d.pop("updated", UNSET)

        gamification_realm_event_type = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            name=name,
            stat_key=stat_key,
            created=created,
            updated=updated,
        )

        gamification_realm_event_type.additional_properties = d
        return gamification_realm_event_type

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
