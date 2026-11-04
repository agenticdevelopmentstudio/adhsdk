from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

T = TypeVar("T", bound="PutMonitoringEndpointsIdResponse200")


@_attrs_define
class PutMonitoringEndpointsIdResponse200:
    """
    Attributes:
        id (str):
        site_id (str):
        user_id (str):
        author_kind (None | str):
        author_id (None | str):
        owner_kind (str):
        owner_id (str):
        kind (str):
        url (str):
        expected_status (int):
        expected_body_contains (None | str):
        timeout_ms (int):
        degraded_threshold_ms (int):
        check_interval_seconds (int):
        is_active (bool):
        created_at (str):
        updated_at (str):
    """

    id: str
    site_id: str
    user_id: str
    author_kind: None | str
    author_id: None | str
    owner_kind: str
    owner_id: str
    kind: str
    url: str
    expected_status: int
    expected_body_contains: None | str
    timeout_ms: int
    degraded_threshold_ms: int
    check_interval_seconds: int
    is_active: bool
    created_at: str
    updated_at: str

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        site_id = self.site_id

        user_id = self.user_id

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        kind = self.kind

        url = self.url

        expected_status = self.expected_status

        expected_body_contains: None | str
        expected_body_contains = self.expected_body_contains

        timeout_ms = self.timeout_ms

        degraded_threshold_ms = self.degraded_threshold_ms

        check_interval_seconds = self.check_interval_seconds

        is_active = self.is_active

        created_at = self.created_at

        updated_at = self.updated_at

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "siteId": site_id,
                "userId": user_id,
                "authorKind": author_kind,
                "authorId": author_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "kind": kind,
                "url": url,
                "expectedStatus": expected_status,
                "expectedBodyContains": expected_body_contains,
                "timeoutMs": timeout_ms,
                "degradedThresholdMs": degraded_threshold_ms,
                "checkIntervalSeconds": check_interval_seconds,
                "isActive": is_active,
                "createdAt": created_at,
                "updatedAt": updated_at,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        site_id = d.pop("siteId")

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

        kind = d.pop("kind")

        url = d.pop("url")

        expected_status = d.pop("expectedStatus")

        def _parse_expected_body_contains(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        expected_body_contains = _parse_expected_body_contains(d.pop("expectedBodyContains"))

        timeout_ms = d.pop("timeoutMs")

        degraded_threshold_ms = d.pop("degradedThresholdMs")

        check_interval_seconds = d.pop("checkIntervalSeconds")

        is_active = d.pop("isActive")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        put_monitoring_endpoints_id_response_200 = cls(
            id=id,
            site_id=site_id,
            user_id=user_id,
            author_kind=author_kind,
            author_id=author_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            kind=kind,
            url=url,
            expected_status=expected_status,
            expected_body_contains=expected_body_contains,
            timeout_ms=timeout_ms,
            degraded_threshold_ms=degraded_threshold_ms,
            check_interval_seconds=check_interval_seconds,
            is_active=is_active,
            created_at=created_at,
            updated_at=updated_at,
        )

        return put_monitoring_endpoints_id_response_200
