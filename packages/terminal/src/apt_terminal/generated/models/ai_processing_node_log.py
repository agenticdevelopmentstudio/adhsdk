from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.ai_processing_log_level import AiProcessingLogLevel

if TYPE_CHECKING:
    from ..models.ai_processing_node_log_data_type_0 import AiProcessingNodeLogDataType0


T = TypeVar("T", bound="AiProcessingNodeLog")


@_attrs_define
class AiProcessingNodeLog:
    """
    Attributes:
        id (int):
        node_id (str):
        occurred_at (str):
        received_at (str):
        level (AiProcessingLogLevel):
        event (str):
        message (str):
        job_id (None | str):
        data (AiProcessingNodeLogDataType0 | None):
    """

    id: int
    node_id: str
    occurred_at: str
    received_at: str
    level: AiProcessingLogLevel
    event: str
    message: str
    job_id: None | str
    data: AiProcessingNodeLogDataType0 | None
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.ai_processing_node_log_data_type_0 import (
            AiProcessingNodeLogDataType0,
        )

        id = self.id

        node_id = self.node_id

        occurred_at = self.occurred_at

        received_at = self.received_at

        level = self.level.value

        event = self.event

        message = self.message

        job_id: None | str
        job_id = self.job_id

        data: dict[str, Any] | None
        if isinstance(self.data, AiProcessingNodeLogDataType0):
            data = self.data.to_dict()
        else:
            data = self.data

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "nodeId": node_id,
                "occurredAt": occurred_at,
                "receivedAt": received_at,
                "level": level,
                "event": event,
                "message": message,
                "jobId": job_id,
                "data": data,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ai_processing_node_log_data_type_0 import (
            AiProcessingNodeLogDataType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        node_id = d.pop("nodeId")

        occurred_at = d.pop("occurredAt")

        received_at = d.pop("receivedAt")

        level = AiProcessingLogLevel(d.pop("level"))

        event = d.pop("event")

        message = d.pop("message")

        def _parse_job_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        job_id = _parse_job_id(d.pop("jobId"))

        def _parse_data(data: object) -> AiProcessingNodeLogDataType0 | None:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                data_type_0 = AiProcessingNodeLogDataType0.from_dict(data)

                return data_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(AiProcessingNodeLogDataType0 | None, data)

        data = _parse_data(d.pop("data"))

        ai_processing_node_log = cls(
            id=id,
            node_id=node_id,
            occurred_at=occurred_at,
            received_at=received_at,
            level=level,
            event=event,
            message=message,
            job_id=job_id,
            data=data,
        )

        ai_processing_node_log.additional_properties = d
        return ai_processing_node_log

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
