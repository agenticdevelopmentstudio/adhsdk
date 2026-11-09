from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1MonitoringHealthChecksBody")


@_attrs_define
class PostV1MonitoringHealthChecksBody:
    """
    Attributes:
        endpoint_id (str):
        status (str):
        checked_at (str):
        response_time_ms (int | None | Unset):
        status_code (int | None | Unset):
        error_message (None | str | Unset):
    """

    endpoint_id: str
    status: str
    checked_at: str
    response_time_ms: int | None | Unset = UNSET
    status_code: int | None | Unset = UNSET
    error_message: None | str | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        endpoint_id = self.endpoint_id

        status = self.status

        checked_at = self.checked_at

        response_time_ms: int | None | Unset
        if isinstance(self.response_time_ms, Unset):
            response_time_ms = UNSET
        else:
            response_time_ms = self.response_time_ms

        status_code: int | None | Unset
        if isinstance(self.status_code, Unset):
            status_code = UNSET
        else:
            status_code = self.status_code

        error_message: None | str | Unset
        if isinstance(self.error_message, Unset):
            error_message = UNSET
        else:
            error_message = self.error_message

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "endpoint_id": endpoint_id,
                "status": status,
                "checked_at": checked_at,
            }
        )
        if response_time_ms is not UNSET:
            field_dict["response_time_ms"] = response_time_ms
        if status_code is not UNSET:
            field_dict["status_code"] = status_code
        if error_message is not UNSET:
            field_dict["error_message"] = error_message

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        endpoint_id = d.pop("endpoint_id")

        status = d.pop("status")

        checked_at = d.pop("checked_at")

        def _parse_response_time_ms(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        response_time_ms = _parse_response_time_ms(d.pop("response_time_ms", UNSET))

        def _parse_status_code(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        status_code = _parse_status_code(d.pop("status_code", UNSET))

        def _parse_error_message(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        error_message = _parse_error_message(d.pop("error_message", UNSET))

        post_v1_monitoring_health_checks_body = cls(
            endpoint_id=endpoint_id,
            status=status,
            checked_at=checked_at,
            response_time_ms=response_time_ms,
            status_code=status_code,
            error_message=error_message,
        )

        return post_v1_monitoring_health_checks_body
