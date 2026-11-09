from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1GamificationEventTypesResponse200DataItem")


@_attrs_define
class GetV1GamificationEventTypesResponse200DataItem:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        name (str): The custom event_type key
        stat_key (str): The gamification stat this event bumps
        created (int | Unset): Unix timestamp, in seconds.
        updated (int | Unset): Unix timestamp, in seconds.
        object_ (Literal['gamification.event_type'] | Unset):
    """

    id: str
    ecosystem_id: str
    name: str
    stat_key: str
    created: int | Unset = UNSET
    updated: int | Unset = UNSET
    object_: Literal["gamification.event_type"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        name = self.name

        stat_key = self.stat_key

        created = self.created

        updated = self.updated

        object_ = self.object_

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
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["gamification.event_type"] | Unset, d.pop("object", UNSET))
        if object_ != "gamification.event_type" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'gamification.event_type', got '{object_}'")

        get_v1_gamification_event_types_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            name=name,
            stat_key=stat_key,
            created=created,
            updated=updated,
            object_=object_,
        )

        get_v1_gamification_event_types_response_200_data_item.additional_properties = d
        return get_v1_gamification_event_types_response_200_data_item

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
