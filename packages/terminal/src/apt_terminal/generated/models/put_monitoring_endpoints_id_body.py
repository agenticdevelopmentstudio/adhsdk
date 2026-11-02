from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="PutMonitoringEndpointsIdBody")


@_attrs_define
class PutMonitoringEndpointsIdBody:
    """
    Attributes:
        site_id (str | Unset):
        kind (str | Unset):
        url (str | Unset):
        expected_status (int | Unset):
        expected_body_contains (None | str | Unset):
        timeout_ms (int | Unset):
        degraded_threshold_ms (int | Unset):
        check_interval_seconds (int | Unset):
        is_active (bool | Unset):
    """

    site_id: str | Unset = UNSET
    kind: str | Unset = UNSET
    url: str | Unset = UNSET
    expected_status: int | Unset = UNSET
    expected_body_contains: None | str | Unset = UNSET
    timeout_ms: int | Unset = UNSET
    degraded_threshold_ms: int | Unset = UNSET
    check_interval_seconds: int | Unset = UNSET
    is_active: bool | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        site_id = self.site_id

        kind = self.kind

        url = self.url

        expected_status = self.expected_status

        expected_body_contains: None | str | Unset
        if isinstance(self.expected_body_contains, Unset):
            expected_body_contains = UNSET
        else:
            expected_body_contains = self.expected_body_contains

        timeout_ms = self.timeout_ms

        degraded_threshold_ms = self.degraded_threshold_ms

        check_interval_seconds = self.check_interval_seconds

        is_active = self.is_active

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if site_id is not UNSET:
            field_dict["siteId"] = site_id
        if kind is not UNSET:
            field_dict["kind"] = kind
        if url is not UNSET:
            field_dict["url"] = url
        if expected_status is not UNSET:
            field_dict["expectedStatus"] = expected_status
        if expected_body_contains is not UNSET:
            field_dict["expectedBodyContains"] = expected_body_contains
        if timeout_ms is not UNSET:
            field_dict["timeoutMs"] = timeout_ms
        if degraded_threshold_ms is not UNSET:
            field_dict["degradedThresholdMs"] = degraded_threshold_ms
        if check_interval_seconds is not UNSET:
            field_dict["checkIntervalSeconds"] = check_interval_seconds
        if is_active is not UNSET:
            field_dict["isActive"] = is_active

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        site_id = d.pop("siteId", UNSET)

        kind = d.pop("kind", UNSET)

        url = d.pop("url", UNSET)

        expected_status = d.pop("expectedStatus", UNSET)

        def _parse_expected_body_contains(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        expected_body_contains = _parse_expected_body_contains(d.pop("expectedBodyContains", UNSET))

        timeout_ms = d.pop("timeoutMs", UNSET)

        degraded_threshold_ms = d.pop("degradedThresholdMs", UNSET)

        check_interval_seconds = d.pop("checkIntervalSeconds", UNSET)

        is_active = d.pop("isActive", UNSET)

        put_monitoring_endpoints_id_body = cls(
            site_id=site_id,
            kind=kind,
            url=url,
            expected_status=expected_status,
            expected_body_contains=expected_body_contains,
            timeout_ms=timeout_ms,
            degraded_threshold_ms=degraded_threshold_ms,
            check_interval_seconds=check_interval_seconds,
            is_active=is_active,
        )

        return put_monitoring_endpoints_id_body
