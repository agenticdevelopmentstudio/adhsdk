from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.ai_processing_log_level import AiProcessingLogLevel
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_processing_nodes_id_logs_body_entries_item_data import (
        PostProcessingNodesIdLogsBodyEntriesItemData,
    )


T = TypeVar("T", bound="PostProcessingNodesIdLogsBodyEntriesItem")


@_attrs_define
class PostProcessingNodesIdLogsBodyEntriesItem:
    """
    Attributes:
        occurred_at (datetime.datetime):
        level (AiProcessingLogLevel):
        event (str):
        message (str): At most 4096 bytes of UTF-8
        job_id (str | Unset):
        data (PostProcessingNodesIdLogsBodyEntriesItemData | Unset):
    """

    occurred_at: datetime.datetime
    level: AiProcessingLogLevel
    event: str
    message: str
    job_id: str | Unset = UNSET
    data: PostProcessingNodesIdLogsBodyEntriesItemData | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        occurred_at = self.occurred_at.isoformat()

        level = self.level.value

        event = self.event

        message = self.message

        job_id = self.job_id

        data: dict[str, Any] | Unset = UNSET
        if not isinstance(self.data, Unset):
            data = self.data.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "occurredAt": occurred_at,
                "level": level,
                "event": event,
                "message": message,
            }
        )
        if job_id is not UNSET:
            field_dict["jobId"] = job_id
        if data is not UNSET:
            field_dict["data"] = data

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_processing_nodes_id_logs_body_entries_item_data import (
            PostProcessingNodesIdLogsBodyEntriesItemData,
        )

        d = dict(src_dict)
        occurred_at = datetime.datetime.fromisoformat(d.pop("occurredAt"))

        level = AiProcessingLogLevel(d.pop("level"))

        event = d.pop("event")

        message = d.pop("message")

        job_id = d.pop("jobId", UNSET)

        _data = d.pop("data", UNSET)
        data: PostProcessingNodesIdLogsBodyEntriesItemData | Unset
        if isinstance(_data, Unset):
            data = UNSET
        else:
            data = PostProcessingNodesIdLogsBodyEntriesItemData.from_dict(_data)

        post_processing_nodes_id_logs_body_entries_item = cls(
            occurred_at=occurred_at,
            level=level,
            event=event,
            message=message,
            job_id=job_id,
            data=data,
        )

        post_processing_nodes_id_logs_body_entries_item.additional_properties = d
        return post_processing_nodes_id_logs_body_entries_item

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
