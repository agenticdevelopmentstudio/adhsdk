from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="GetMonitoringHealthChecksResponse200Item")


@_attrs_define
class GetMonitoringHealthChecksResponse200Item:
    """
    Attributes:
        id (str):
        endpoint_id (str):
        user_id (str):
        author_kind (None | str):
        author_id (None | str):
        owner_kind (str):
        owner_id (str):
        status (str):
        response_time_ms (int | None):
        status_code (int | None):
        error_message (None | str):
        checked_at (str):
    """

    id: str
    endpoint_id: str
    user_id: str
    author_kind: None | str
    author_id: None | str
    owner_kind: str
    owner_id: str
    status: str
    response_time_ms: int | None
    status_code: int | None
    error_message: None | str
    checked_at: str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        endpoint_id = self.endpoint_id

        user_id = self.user_id

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        status = self.status

        response_time_ms: int | None
        response_time_ms = self.response_time_ms

        status_code: int | None
        status_code = self.status_code

        error_message: None | str
        error_message = self.error_message

        checked_at = self.checked_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "endpointId": endpoint_id,
                "userId": user_id,
                "authorKind": author_kind,
                "authorId": author_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "status": status,
                "responseTimeMs": response_time_ms,
                "statusCode": status_code,
                "errorMessage": error_message,
                "checkedAt": checked_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        endpoint_id = d.pop("endpointId")

        user_id = d.pop("userId")

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("authorKind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("authorId"))

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        status = d.pop("status")

        def _parse_response_time_ms(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        response_time_ms = _parse_response_time_ms(d.pop("responseTimeMs"))

        def _parse_status_code(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        status_code = _parse_status_code(d.pop("statusCode"))

        def _parse_error_message(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        error_message = _parse_error_message(d.pop("errorMessage"))

        checked_at = d.pop("checkedAt")

        get_monitoring_health_checks_response_200_item = cls(
            id=id,
            endpoint_id=endpoint_id,
            user_id=user_id,
            author_kind=author_kind,
            author_id=author_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            status=status,
            response_time_ms=response_time_ms,
            status_code=status_code,
            error_message=error_message,
            checked_at=checked_at,
        )

        return get_monitoring_health_checks_response_200_item
