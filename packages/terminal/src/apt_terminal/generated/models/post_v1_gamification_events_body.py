from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostV1GamificationEventsBody")


@_attrs_define
class PostV1GamificationEventsBody:
    """
    Attributes:
        name (str): A custom event type defined for this realm
        subject_type (str):
        subject_id (str):
        dedupe_key (str): Required idempotency key the caller owns (e.g. the source event id); the same key never
            double-counts
        ecosystem (str): Scopes the call; the caller passes it as a parameter, not in the path.
    """

    name: str
    subject_type: str
    subject_id: str
    dedupe_key: str
    ecosystem: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        subject_type = self.subject_type

        subject_id = self.subject_id

        dedupe_key = self.dedupe_key

        ecosystem = self.ecosystem

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
                "subject_type": subject_type,
                "subject_id": subject_id,
                "dedupe_key": dedupe_key,
                "ecosystem": ecosystem,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        subject_type = d.pop("subject_type")

        subject_id = d.pop("subject_id")

        dedupe_key = d.pop("dedupe_key")

        ecosystem = d.pop("ecosystem")

        post_v1_gamification_events_body = cls(
            name=name,
            subject_type=subject_type,
            subject_id=subject_id,
            dedupe_key=dedupe_key,
            ecosystem=ecosystem,
        )

        post_v1_gamification_events_body.additional_properties = d
        return post_v1_gamification_events_body

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
