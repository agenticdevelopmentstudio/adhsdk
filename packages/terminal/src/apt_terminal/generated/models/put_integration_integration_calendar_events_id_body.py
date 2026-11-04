from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutIntegrationIntegrationCalendarEventsIdBody")


@_attrs_define
class PutIntegrationIntegrationCalendarEventsIdBody:
    """
    Attributes:
        title (str | Unset):
        description (None | str | Unset):
        start_time (None | str | Unset):
        end_time (None | str | Unset):
        start_date (None | str | Unset):
        end_date (None | str | Unset):
        is_all_day (bool | Unset):
        location (None | str | Unset):
        source (str | Unset):
        external_id (str | Unset):
        connection_id (None | str | Unset):
        calendar_name (None | str | Unset):
        calendar_color (None | str | Unset):
        status (str | Unset):
        organizer (None | str | Unset):
        attendees (None | str | Unset):
        reminders (None | str | Unset):
        url (None | str | Unset):
        ai_extraction (None | str | Unset):
        ecosystem_id (str | Unset):
    """

    title: str | Unset = UNSET
    description: None | str | Unset = UNSET
    start_time: None | str | Unset = UNSET
    end_time: None | str | Unset = UNSET
    start_date: None | str | Unset = UNSET
    end_date: None | str | Unset = UNSET
    is_all_day: bool | Unset = UNSET
    location: None | str | Unset = UNSET
    source: str | Unset = UNSET
    external_id: str | Unset = UNSET
    connection_id: None | str | Unset = UNSET
    calendar_name: None | str | Unset = UNSET
    calendar_color: None | str | Unset = UNSET
    status: str | Unset = UNSET
    organizer: None | str | Unset = UNSET
    attendees: None | str | Unset = UNSET
    reminders: None | str | Unset = UNSET
    url: None | str | Unset = UNSET
    ai_extraction: None | str | Unset = UNSET
    ecosystem_id: str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        title = self.title

        description: None | str | Unset
        if isinstance(self.description, Unset):
            description = UNSET
        else:
            description = self.description

        start_time: None | str | Unset
        if isinstance(self.start_time, Unset):
            start_time = UNSET
        else:
            start_time = self.start_time

        end_time: None | str | Unset
        if isinstance(self.end_time, Unset):
            end_time = UNSET
        else:
            end_time = self.end_time

        start_date: None | str | Unset
        if isinstance(self.start_date, Unset):
            start_date = UNSET
        else:
            start_date = self.start_date

        end_date: None | str | Unset
        if isinstance(self.end_date, Unset):
            end_date = UNSET
        else:
            end_date = self.end_date

        is_all_day = self.is_all_day

        location: None | str | Unset
        if isinstance(self.location, Unset):
            location = UNSET
        else:
            location = self.location

        source = self.source

        external_id = self.external_id

        connection_id: None | str | Unset
        if isinstance(self.connection_id, Unset):
            connection_id = UNSET
        else:
            connection_id = self.connection_id

        calendar_name: None | str | Unset
        if isinstance(self.calendar_name, Unset):
            calendar_name = UNSET
        else:
            calendar_name = self.calendar_name

        calendar_color: None | str | Unset
        if isinstance(self.calendar_color, Unset):
            calendar_color = UNSET
        else:
            calendar_color = self.calendar_color

        status = self.status

        organizer: None | str | Unset
        if isinstance(self.organizer, Unset):
            organizer = UNSET
        else:
            organizer = self.organizer

        attendees: None | str | Unset
        if isinstance(self.attendees, Unset):
            attendees = UNSET
        else:
            attendees = self.attendees

        reminders: None | str | Unset
        if isinstance(self.reminders, Unset):
            reminders = UNSET
        else:
            reminders = self.reminders

        url: None | str | Unset
        if isinstance(self.url, Unset):
            url = UNSET
        else:
            url = self.url

        ai_extraction: None | str | Unset
        if isinstance(self.ai_extraction, Unset):
            ai_extraction = UNSET
        else:
            ai_extraction = self.ai_extraction

        ecosystem_id = self.ecosystem_id

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if title is not UNSET:
            field_dict["title"] = title
        if description is not UNSET:
            field_dict["description"] = description
        if start_time is not UNSET:
            field_dict["startTime"] = start_time
        if end_time is not UNSET:
            field_dict["endTime"] = end_time
        if start_date is not UNSET:
            field_dict["startDate"] = start_date
        if end_date is not UNSET:
            field_dict["endDate"] = end_date
        if is_all_day is not UNSET:
            field_dict["isAllDay"] = is_all_day
        if location is not UNSET:
            field_dict["location"] = location
        if source is not UNSET:
            field_dict["source"] = source
        if external_id is not UNSET:
            field_dict["externalId"] = external_id
        if connection_id is not UNSET:
            field_dict["connectionId"] = connection_id
        if calendar_name is not UNSET:
            field_dict["calendarName"] = calendar_name
        if calendar_color is not UNSET:
            field_dict["calendarColor"] = calendar_color
        if status is not UNSET:
            field_dict["status"] = status
        if organizer is not UNSET:
            field_dict["organizer"] = organizer
        if attendees is not UNSET:
            field_dict["attendees"] = attendees
        if reminders is not UNSET:
            field_dict["reminders"] = reminders
        if url is not UNSET:
            field_dict["url"] = url
        if ai_extraction is not UNSET:
            field_dict["aiExtraction"] = ai_extraction
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        title = d.pop("title", UNSET)

        def _parse_description(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        description = _parse_description(d.pop("description", UNSET))

        def _parse_start_time(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        start_time = _parse_start_time(d.pop("startTime", UNSET))

        def _parse_end_time(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        end_time = _parse_end_time(d.pop("endTime", UNSET))

        def _parse_start_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        start_date = _parse_start_date(d.pop("startDate", UNSET))

        def _parse_end_date(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        end_date = _parse_end_date(d.pop("endDate", UNSET))

        is_all_day = d.pop("isAllDay", UNSET)

        def _parse_location(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        location = _parse_location(d.pop("location", UNSET))

        source = d.pop("source", UNSET)

        external_id = d.pop("externalId", UNSET)

        def _parse_connection_id(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        connection_id = _parse_connection_id(d.pop("connectionId", UNSET))

        def _parse_calendar_name(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        calendar_name = _parse_calendar_name(d.pop("calendarName", UNSET))

        def _parse_calendar_color(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        calendar_color = _parse_calendar_color(d.pop("calendarColor", UNSET))

        status = d.pop("status", UNSET)

        def _parse_organizer(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        organizer = _parse_organizer(d.pop("organizer", UNSET))

        def _parse_attendees(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        attendees = _parse_attendees(d.pop("attendees", UNSET))

        def _parse_reminders(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        reminders = _parse_reminders(d.pop("reminders", UNSET))

        def _parse_url(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        url = _parse_url(d.pop("url", UNSET))

        def _parse_ai_extraction(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        ai_extraction = _parse_ai_extraction(d.pop("aiExtraction", UNSET))

        ecosystem_id = d.pop("ecosystemId", UNSET)

        put_integration_integration_calendar_events_id_body = cls(
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
            ecosystem_id=ecosystem_id,
        )

        return put_integration_integration_calendar_events_id_body
