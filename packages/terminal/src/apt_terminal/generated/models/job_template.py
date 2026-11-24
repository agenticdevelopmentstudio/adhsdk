from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.job_template_status import JobTemplateStatus

if TYPE_CHECKING:
    from ..models.job_template_draft import JobTemplateDraft


T = TypeVar("T", bound="JobTemplate")


@_attrs_define
class JobTemplate:
    """
    Attributes:
        id (UUID):
        key (str): Lower case letters, digits and hyphens; unique per ecosystem.
        name (str):
        description (None | str):
        status (JobTemplateStatus):
        latest_version (int | None): Null until the first publish.
        latest_has_script (bool | None): Whether the latest version has a script step (it then cannot be offered).
        latest_published_at (datetime.datetime | None):
        offered_set_ids (list[UUID]):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        draft (JobTemplateDraft):
    """

    id: UUID
    key: str
    name: str
    description: None | str
    status: JobTemplateStatus
    latest_version: int | None
    latest_has_script: bool | None
    latest_published_at: datetime.datetime | None
    offered_set_ids: list[UUID]
    created: int
    updated: int
    draft: JobTemplateDraft
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        key = self.key

        name = self.name

        description: None | str
        description = self.description

        status = self.status.value

        latest_version: int | None
        latest_version = self.latest_version

        latest_has_script: bool | None
        latest_has_script = self.latest_has_script

        latest_published_at: None | str
        if isinstance(self.latest_published_at, datetime.datetime):
            latest_published_at = self.latest_published_at.isoformat()
        else:
            latest_published_at = self.latest_published_at

        offered_set_ids = []
        for offered_set_ids_item_data in self.offered_set_ids:
            offered_set_ids_item = str(offered_set_ids_item_data)
            offered_set_ids.append(offered_set_ids_item)

        created = self.created

        updated = self.updated

        draft = self.draft.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "key": key,
                "name": name,
                "description": description,
                "status": status,
                "latest_version": latest_version,
                "latest_has_script": latest_has_script,
                "latest_published_at": latest_published_at,
                "offered_set_ids": offered_set_ids,
                "created": created,
                "updated": updated,
                "draft": draft,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.job_template_draft import JobTemplateDraft

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        key = d.pop("key")

        name = d.pop("name")

        def _parse_description(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        description = _parse_description(d.pop("description"))

        status = JobTemplateStatus(d.pop("status"))

        def _parse_latest_version(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        latest_version = _parse_latest_version(d.pop("latest_version"))

        def _parse_latest_has_script(data: object) -> bool | None:
            if data is None:
                return data
            return cast(bool | None, data)

        latest_has_script = _parse_latest_has_script(d.pop("latest_has_script"))

        def _parse_latest_published_at(data: object) -> datetime.datetime | None:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                latest_published_at_type_0 = datetime.datetime.fromisoformat(data)

                return latest_published_at_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None, data)

        latest_published_at = _parse_latest_published_at(d.pop("latest_published_at"))

        offered_set_ids = []
        _offered_set_ids = d.pop("offered_set_ids")
        for offered_set_ids_item_data in _offered_set_ids:
            offered_set_ids_item = UUID(offered_set_ids_item_data)

            offered_set_ids.append(offered_set_ids_item)

        created = d.pop("created")

        updated = d.pop("updated")

        draft = JobTemplateDraft.from_dict(d.pop("draft"))

        job_template = cls(
            id=id,
            key=key,
            name=name,
            description=description,
            status=status,
            latest_version=latest_version,
            latest_has_script=latest_has_script,
            latest_published_at=latest_published_at,
            offered_set_ids=offered_set_ids,
            created=created,
            updated=updated,
            draft=draft,
        )

        job_template.additional_properties = d
        return job_template

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
