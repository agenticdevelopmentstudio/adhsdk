from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.job_trigger_create_kind import JobTriggerCreateKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="JobTriggerCreate")


@_attrs_define
class JobTriggerCreate:
    """schedule: `{ kind, cron, timeZone, enabled? }`; event: `{ kind, eventTypes, enabled? }`; inbound: `{ kind, enabled?
    }`.

        Attributes:
            kind (JobTriggerCreateKind):
            cron (str | Unset):
            time_zone (str | Unset): An IANA zone.
            event_types (list[str] | Unset):
            enabled (bool | Unset):
    """

    kind: JobTriggerCreateKind
    cron: str | Unset = UNSET
    time_zone: str | Unset = UNSET
    event_types: list[str] | Unset = UNSET
    enabled: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kind = self.kind.value

        cron = self.cron

        time_zone = self.time_zone

        event_types: list[str] | Unset = UNSET
        if not isinstance(self.event_types, Unset):
            event_types = self.event_types

        enabled = self.enabled

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "kind": kind,
            }
        )
        if cron is not UNSET:
            field_dict["cron"] = cron
        if time_zone is not UNSET:
            field_dict["time_zone"] = time_zone
        if event_types is not UNSET:
            field_dict["event_types"] = event_types
        if enabled is not UNSET:
            field_dict["enabled"] = enabled

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        kind = JobTriggerCreateKind(d.pop("kind"))

        cron = d.pop("cron", UNSET)

        time_zone = d.pop("time_zone", UNSET)

        event_types = cast(list[str], d.pop("event_types", UNSET))

        enabled = d.pop("enabled", UNSET)

        job_trigger_create = cls(
            kind=kind,
            cron=cron,
            time_zone=time_zone,
            event_types=event_types,
            enabled=enabled,
        )

        job_trigger_create.additional_properties = d
        return job_trigger_create

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
