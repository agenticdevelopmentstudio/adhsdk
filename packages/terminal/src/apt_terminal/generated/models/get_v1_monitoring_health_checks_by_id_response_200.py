from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1MonitoringHealthChecksByIdResponse200")


@_attrs_define
class GetV1MonitoringHealthChecksByIdResponse200:
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
        object_ (Literal['monitoring.health_check'] | Unset):
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
    object_: Literal["monitoring.health_check"] | Unset = UNSET

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

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "endpoint_id": endpoint_id,
                "user_id": user_id,
                "author_kind": author_kind,
                "author_id": author_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "status": status,
                "response_time_ms": response_time_ms,
                "status_code": status_code,
                "error_message": error_message,
                "checked_at": checked_at,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        endpoint_id = d.pop("endpoint_id")

        user_id = d.pop("user_id")

        def _parse_author_kind(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_kind = _parse_author_kind(d.pop("author_kind"))

        def _parse_author_id(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        author_id = _parse_author_id(d.pop("author_id"))

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        status = d.pop("status")

        def _parse_response_time_ms(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        response_time_ms = _parse_response_time_ms(d.pop("response_time_ms"))

        def _parse_status_code(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        status_code = _parse_status_code(d.pop("status_code"))

        def _parse_error_message(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        error_message = _parse_error_message(d.pop("error_message"))

        checked_at = d.pop("checked_at")

        object_ = cast(Literal["monitoring.health_check"] | Unset, d.pop("object", UNSET))
        if object_ != "monitoring.health_check" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'monitoring.health_check', got '{object_}'")

        get_v1_monitoring_health_checks_by_id_response_200 = cls(
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
            object_=object_,
        )

        return get_v1_monitoring_health_checks_by_id_response_200
