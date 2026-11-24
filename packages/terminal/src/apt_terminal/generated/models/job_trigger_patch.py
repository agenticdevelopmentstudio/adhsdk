from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="JobTriggerPatch")


@_attrs_define
class JobTriggerPatch:
    """cron and timeZone for a schedule only; eventTypes for an event trigger only.

    Attributes:
        enabled (bool | Unset):
        cron (str | Unset):
        time_zone (str | Unset):
        event_types (list[str] | Unset):
    """

    enabled: bool | Unset = UNSET
    cron: str | Unset = UNSET
    time_zone: str | Unset = UNSET
    event_types: list[str] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        enabled = self.enabled

        cron = self.cron

        time_zone = self.time_zone

        event_types: list[str] | Unset = UNSET
        if not isinstance(self.event_types, Unset):
            event_types = self.event_types

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if enabled is not UNSET:
            field_dict["enabled"] = enabled
        if cron is not UNSET:
            field_dict["cron"] = cron
        if time_zone is not UNSET:
            field_dict["time_zone"] = time_zone
        if event_types is not UNSET:
            field_dict["event_types"] = event_types

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        enabled = d.pop("enabled", UNSET)

        cron = d.pop("cron", UNSET)

        time_zone = d.pop("time_zone", UNSET)

        event_types = cast(list[str], d.pop("event_types", UNSET))

        job_trigger_patch = cls(
            enabled=enabled,
            cron=cron,
            time_zone=time_zone,
            event_types=event_types,
        )

        return job_trigger_patch
