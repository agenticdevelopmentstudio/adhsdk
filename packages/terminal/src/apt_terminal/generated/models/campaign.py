from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.campaign_status import CampaignStatus
from ..types import UNSET, Unset

T = TypeVar("T", bound="Campaign")


@_attrs_define
class Campaign:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        list_id (str):
        name (str):
        subject (str):
        html_body (str):
        text_body (str):
        from_name (None | str):
        status (CampaignStatus):
        recipient_count (int):
        sent_count (int):
        failed_count (int):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        created_by (None | str | Unset):
        scheduled_at (None | str | Unset):
        started_at (None | str | Unset):
        completed_at (None | str | Unset):
    """

    id: str
    ecosystem_id: str
    list_id: str
    name: str
    subject: str
    html_body: str
    text_body: str
    from_name: None | str
    status: CampaignStatus
    recipient_count: int
    sent_count: int
    failed_count: int
    created: int
    updated: int
    created_by: None | str | Unset = UNSET
    scheduled_at: None | str | Unset = UNSET
    started_at: None | str | Unset = UNSET
    completed_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        list_id = self.list_id

        name = self.name

        subject = self.subject

        html_body = self.html_body

        text_body = self.text_body

        from_name: None | str
        from_name = self.from_name

        status = self.status.value

        recipient_count = self.recipient_count

        sent_count = self.sent_count

        failed_count = self.failed_count

        created = self.created

        updated = self.updated

        created_by: None | str | Unset
        if isinstance(self.created_by, Unset):
            created_by = UNSET
        else:
            created_by = self.created_by

        scheduled_at: None | str | Unset
        if isinstance(self.scheduled_at, Unset):
            scheduled_at = UNSET
        else:
            scheduled_at = self.scheduled_at

        started_at: None | str | Unset
        if isinstance(self.started_at, Unset):
            started_at = UNSET
        else:
            started_at = self.started_at

        completed_at: None | str | Unset
        if isinstance(self.completed_at, Unset):
            completed_at = UNSET
        else:
            completed_at = self.completed_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "list_id": list_id,
                "name": name,
                "subject": subject,
                "html_body": html_body,
                "text_body": text_body,
                "from_name": from_name,
                "status": status,
                "recipient_count": recipient_count,
                "sent_count": sent_count,
                "failed_count": failed_count,
                "created": created,
                "updated": updated,
            }
        )
        if created_by is not UNSET:
            field_dict["created_by"] = created_by
        if scheduled_at is not UNSET:
            field_dict["scheduled_at"] = scheduled_at
        if started_at is not UNSET:
            field_dict["started_at"] = started_at
        if completed_at is not UNSET:
            field_dict["completed_at"] = completed_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        list_id = d.pop("list_id")

        name = d.pop("name")

        subject = d.pop("subject")

        html_body = d.pop("html_body")

        text_body = d.pop("text_body")

        def _parse_from_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        from_name = _parse_from_name(d.pop("from_name"))

        status = CampaignStatus(d.pop("status"))

        recipient_count = d.pop("recipient_count")

        sent_count = d.pop("sent_count")

        failed_count = d.pop("failed_count")

        created = d.pop("created")

        updated = d.pop("updated")

        def _parse_created_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        created_by = _parse_created_by(d.pop("created_by", UNSET))

        def _parse_scheduled_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        scheduled_at = _parse_scheduled_at(d.pop("scheduled_at", UNSET))

        def _parse_started_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        started_at = _parse_started_at(d.pop("started_at", UNSET))

        def _parse_completed_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        completed_at = _parse_completed_at(d.pop("completed_at", UNSET))

        campaign = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            list_id=list_id,
            name=name,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
            from_name=from_name,
            status=status,
            recipient_count=recipient_count,
            sent_count=sent_count,
            failed_count=failed_count,
            created=created,
            updated=updated,
            created_by=created_by,
            scheduled_at=scheduled_at,
            started_at=started_at,
            completed_at=completed_at,
        )

        campaign.additional_properties = d
        return campaign

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
