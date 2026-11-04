from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetIntegrationIntegrationCalendarEventsIdResponse200")


@_attrs_define
class GetIntegrationIntegrationCalendarEventsIdResponse200:
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
        created_at (str):
        updated_at (str):
        is_deleted (bool):
        customer_id (str):
        owner_kind (str):
        owner_id (str):
        deleted_at (None | str):
        ecosystem_id (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
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
    created_at: str
    updated_at: str
    is_deleted: bool
    customer_id: str
    owner_kind: str
    owner_id: str
    deleted_at: None | str
    ecosystem_id: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int

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

        created_at = self.created_at

        updated_at = self.updated_at

        is_deleted = self.is_deleted

        customer_id = self.customer_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        deleted_at: None | str
        deleted_at = self.deleted_at

        ecosystem_id = self.ecosystem_id

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "title": title,
                "description": description,
                "startTime": start_time,
                "endTime": end_time,
                "startDate": start_date,
                "endDate": end_date,
                "isAllDay": is_all_day,
                "location": location,
                "source": source,
                "externalId": external_id,
                "connectionId": connection_id,
                "calendarName": calendar_name,
                "calendarColor": calendar_color,
                "status": status,
                "organizer": organizer,
                "attendees": attendees,
                "reminders": reminders,
                "url": url,
                "aiExtraction": ai_extraction,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "isDeleted": is_deleted,
                "customerId": customer_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "deletedAt": deleted_at,
                "ecosystemId": ecosystem_id,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
            }
        )

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

        start_time = _parse_start_time(d.pop("startTime"))

        def _parse_end_time(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        end_time = _parse_end_time(d.pop("endTime"))

        def _parse_start_date(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        start_date = _parse_start_date(d.pop("startDate"))

        def _parse_end_date(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        end_date = _parse_end_date(d.pop("endDate"))

        is_all_day = d.pop("isAllDay")

        def _parse_location(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        location = _parse_location(d.pop("location"))

        source = d.pop("source")

        external_id = d.pop("externalId")

        def _parse_connection_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        connection_id = _parse_connection_id(d.pop("connectionId"))

        def _parse_calendar_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        calendar_name = _parse_calendar_name(d.pop("calendarName"))

        def _parse_calendar_color(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        calendar_color = _parse_calendar_color(d.pop("calendarColor"))

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

        ai_extraction = _parse_ai_extraction(d.pop("aiExtraction"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        is_deleted = d.pop("isDeleted")

        customer_id = d.pop("customerId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        ecosystem_id = d.pop("ecosystemId")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

        get_integration_integration_calendar_events_id_response_200 = cls(
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
            created_at=created_at,
            updated_at=updated_at,
            is_deleted=is_deleted,
            customer_id=customer_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            deleted_at=deleted_at,
            ecosystem_id=ecosystem_id,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
        )

        return get_integration_integration_calendar_events_id_response_200
