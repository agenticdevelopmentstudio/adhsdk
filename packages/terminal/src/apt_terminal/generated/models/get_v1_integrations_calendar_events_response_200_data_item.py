from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1IntegrationsCalendarEventsResponse200DataItem")


@_attrs_define
class GetV1IntegrationsCalendarEventsResponse200DataItem:
    """
    Attributes:
        id (str):
        title (str):
        description (None | str):
        start_time (None | str):
        end_time (None | str):
        start_date (None | str):
        end_date (None | str):
        is_all_day (bool):
        location (None | str):
        source (str):
        external_id (str):
        connection_id (None | str):
        calendar_name (None | str):
        calendar_color (None | str):
        status (str):
        organizer (None | str):
        attendees (None | str):
        reminders (None | str):
        url (None | str):
        ai_extraction (None | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        is_deleted (bool):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        object_ (Literal['integrations.calendar_event'] | Unset):
    """

    id: str
    title: str
    description: None | str
    start_time: None | str
    end_time: None | str
    start_date: None | str
    end_date: None | str
    is_all_day: bool
    location: None | str
    source: str
    external_id: str
    connection_id: None | str
    calendar_name: None | str
    calendar_color: None | str
    status: str
    organizer: None | str
    attendees: None | str
    reminders: None | str
    url: None | str
    ai_extraction: None | str
    created: int
    updated: int
    is_deleted: bool
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    ecosystem_id: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    object_: Literal["integrations.calendar_event"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        title = self.title

        description: None | str
        description = self.description

        start_time: None | str
        start_time = self.start_time

        end_time: None | str
        end_time = self.end_time

        start_date: None | str
        start_date = self.start_date

        end_date: None | str
        end_date = self.end_date

        is_all_day = self.is_all_day

        location: None | str
        location = self.location

        source = self.source

        external_id = self.external_id

        connection_id: None | str
        connection_id = self.connection_id

        calendar_name: None | str
        calendar_name = self.calendar_name

        calendar_color: None | str
        calendar_color = self.calendar_color

        status = self.status

        organizer: None | str
        organizer = self.organizer

        attendees: None | str
        attendees = self.attendees

        reminders: None | str
        reminders = self.reminders

        url: None | str
        url = self.url

        ai_extraction: None | str
        ai_extraction = self.ai_extraction

        created = self.created

        updated = self.updated

        is_deleted = self.is_deleted

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "title": title,
                "description": description,
                "start_time": start_time,
                "end_time": end_time,
                "start_date": start_date,
                "end_date": end_date,
                "is_all_day": is_all_day,
                "location": location,
                "source": source,
                "external_id": external_id,
                "connection_id": connection_id,
                "calendar_name": calendar_name,
                "calendar_color": calendar_color,
                "status": status,
                "organizer": organizer,
                "attendees": attendees,
                "reminders": reminders,
                "url": url,
                "ai_extraction": ai_extraction,
                "created": created,
                "updated": updated,
                "is_deleted": is_deleted,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "deleted_at": deleted_at,
                "ecosystem_id": ecosystem_id,
                "sync_version": sync_version,
                "sync_stamped_at": sync_stamped_at,
                "sync_txid": sync_txid,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        title = d.pop("title")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        def _parse_start_time(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        start_time = _parse_start_time(d.pop("start_time"))

        def _parse_end_time(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        end_time = _parse_end_time(d.pop("end_time"))

        def _parse_start_date(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        start_date = _parse_start_date(d.pop("start_date"))

        def _parse_end_date(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        end_date = _parse_end_date(d.pop("end_date"))

        is_all_day = d.pop("is_all_day")

        def _parse_location(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        location = _parse_location(d.pop("location"))

        source = d.pop("source")

        external_id = d.pop("external_id")

        def _parse_connection_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        connection_id = _parse_connection_id(d.pop("connection_id"))

        def _parse_calendar_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        calendar_name = _parse_calendar_name(d.pop("calendar_name"))

        def _parse_calendar_color(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        calendar_color = _parse_calendar_color(d.pop("calendar_color"))

        status = d.pop("status")

        def _parse_organizer(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        organizer = _parse_organizer(d.pop("organizer"))

        def _parse_attendees(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        attendees = _parse_attendees(d.pop("attendees"))

        def _parse_reminders(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        reminders = _parse_reminders(d.pop("reminders"))

        def _parse_url(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        url = _parse_url(d.pop("url"))

        def _parse_ai_extraction(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        ai_extraction = _parse_ai_extraction(d.pop("ai_extraction"))

        created = d.pop("created")

        updated = d.pop("updated")

        is_deleted = d.pop("is_deleted")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        ecosystem_id = d.pop("ecosystem_id")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

        object_ = cast(Literal["integrations.calendar_event"] | Unset, d.pop("object", UNSET))
        if object_ != "integrations.calendar_event" and not isinstance(object_, Unset):
            raise ValueError(
                f"object must match const 'integrations.calendar_event', got '{object_}'"
            )

        get_v1_integrations_calendar_events_response_200_data_item = cls(
            id=id,
            title=title,
            description=description,
            start_time=start_time,
            end_time=end_time,
            start_date=start_date,
            end_date=end_date,
            is_all_day=is_all_day,
            location=location,
            source=source,
            external_id=external_id,
            connection_id=connection_id,
            calendar_name=calendar_name,
            calendar_color=calendar_color,
            status=status,
            organizer=organizer,
            attendees=attendees,
            reminders=reminders,
            url=url,
            ai_extraction=ai_extraction,
            created=created,
            updated=updated,
            is_deleted=is_deleted,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            object_=object_,
        )

        return get_v1_integrations_calendar_events_response_200_data_item
