from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.job_trigger_kind import JobTriggerKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="JobTrigger")


@_attrs_define
class JobTrigger:
    """
    Attributes:
        id (UUID):
        instance_id (UUID):
        kind (JobTriggerKind):
        cron (None | str):
        time_zone (None | str):
        event_types (list[str] | None):
        enabled (bool):
        next_fire_at (datetime.datetime | None):
        last_fired_at (datetime.datetime | None):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        secret (str | Unset): An inbound trigger's secret, only in the create answer. Send it as `X-ADH-Trigger-Secret`
            to `POST /public/jobs/hooks/{id}`.
    """

    id: UUID
    instance_id: UUID
    kind: JobTriggerKind
    cron: None | str
    time_zone: None | str
    event_types: list[str] | None
    enabled: bool
    next_fire_at: datetime.datetime | None
    last_fired_at: datetime.datetime | None
    created: int
    updated: int
    secret: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        instance_id = str(self.instance_id)

        kind = self.kind.value

        cron: None | str
        cron = self.cron

        time_zone: None | str
        time_zone = self.time_zone

        event_types: list[str] | None
        if isinstance(self.event_types, list):
            event_types = self.event_types

        else:
            event_types = self.event_types

        enabled = self.enabled

        next_fire_at: None | str
        if isinstance(self.next_fire_at, datetime.datetime):
            next_fire_at = self.next_fire_at.isoformat()
        else:
            next_fire_at = self.next_fire_at

        last_fired_at: None | str
        if isinstance(self.last_fired_at, datetime.datetime):
            last_fired_at = self.last_fired_at.isoformat()
        else:
            last_fired_at = self.last_fired_at

        created = self.created

        updated = self.updated

        secret = self.secret

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "instance_id": instance_id,
                "kind": kind,
                "cron": cron,
                "time_zone": time_zone,
                "event_types": event_types,
                "enabled": enabled,
                "next_fire_at": next_fire_at,
                "last_fired_at": last_fired_at,
                "created": created,
                "updated": updated,
            }
        )
        if secret is not UNSET:
            field_dict["secret"] = secret

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = UUID(d.pop("id"))

        instance_id = UUID(d.pop("instance_id"))

        kind = JobTriggerKind(d.pop("kind"))

        def _parse_cron(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        cron = _parse_cron(d.pop("cron"))

        def _parse_time_zone(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        time_zone = _parse_time_zone(d.pop("time_zone"))

        def _parse_event_types(data: object) -> list[str] | None:
            if data is None:
                return data
            try:
                if not isinstance(data, list):
                    raise TypeError()
                event_types_type_0 = cast(list[str], data)

                return event_types_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(list[str] | None, data)

        event_types = _parse_event_types(d.pop("event_types"))

        enabled = d.pop("enabled")

        def _parse_next_fire_at(data: object) -> datetime.datetime | None:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                next_fire_at_type_0 = datetime.datetime.fromisoformat(data)

                return next_fire_at_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None, data)

        next_fire_at = _parse_next_fire_at(d.pop("next_fire_at"))

        def _parse_last_fired_at(data: object) -> datetime.datetime | None:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                last_fired_at_type_0 = datetime.datetime.fromisoformat(data)

                return last_fired_at_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None, data)

        last_fired_at = _parse_last_fired_at(d.pop("last_fired_at"))

        created = d.pop("created")

        updated = d.pop("updated")

        secret = d.pop("secret", UNSET)

        job_trigger = cls(
            id=id,
            instance_id=instance_id,
            kind=kind,
            cron=cron,
            time_zone=time_zone,
            event_types=event_types,
            enabled=enabled,
            next_fire_at=next_fire_at,
            last_fired_at=last_fired_at,
            created=created,
            updated=updated,
            secret=secret,
        )

        job_trigger.additional_properties = d
        return job_trigger

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
