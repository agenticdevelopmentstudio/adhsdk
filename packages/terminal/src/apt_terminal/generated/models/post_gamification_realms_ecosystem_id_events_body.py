from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostGamificationRealmsEcosystemIdEventsBody")


@_attrs_define
class PostGamificationRealmsEcosystemIdEventsBody:
    """
    Attributes:
        name (str): A custom event type defined for this realm
        subject_type (str):
        subject_id (str):
        dedupe_key (str): Required idempotency key the caller owns (e.g. the source event id); the same key never
            double-counts
    """

    name: str
    subject_type: str
    subject_id: str
    dedupe_key: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        subject_type = self.subject_type

        subject_id = self.subject_id

        dedupe_key = self.dedupe_key

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
                "subjectType": subject_type,
                "subjectId": subject_id,
                "dedupeKey": dedupe_key,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        name = d.pop("name")

        subject_type = d.pop("subjectType")

        subject_id = d.pop("subjectId")

        dedupe_key = d.pop("dedupeKey")

        post_gamification_realms_ecosystem_id_events_body = cls(
            name=name,
            subject_type=subject_type,
            subject_id=subject_id,
            dedupe_key=dedupe_key,
        )

        post_gamification_realms_ecosystem_id_events_body.additional_properties = d
        return post_gamification_realms_ecosystem_id_events_body

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
