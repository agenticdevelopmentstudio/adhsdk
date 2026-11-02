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
        created_at (str | Unset):
        updated_at (str | Unset):
    """

    id: str
    ecosystem_id: str
    name: str
    stat_key: str
    created_at: str | Unset = UNSET
    updated_at: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        name = self.name

        stat_key = self.stat_key

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "name": name,
                "statKey": stat_key,
            }
        )
        if created_at is not UNSET:
            field_dict["createdAt"] = created_at
        if updated_at is not UNSET:
            field_dict["updatedAt"] = updated_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        name = d.pop("name")

        stat_key = d.pop("statKey")

        created_at = d.pop("createdAt", UNSET)

        updated_at = d.pop("updatedAt", UNSET)

        gamification_realm_event_type = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            name=name,
            stat_key=stat_key,
            created_at=created_at,
            updated_at=updated_at,
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
