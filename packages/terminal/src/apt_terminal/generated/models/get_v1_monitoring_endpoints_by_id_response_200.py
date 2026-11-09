from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1MonitoringEndpointsByIdResponse200")


@_attrs_define
class GetV1MonitoringEndpointsByIdResponse200:
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
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        object_ (Literal['monitoring.endpoint'] | Unset):
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
    created: int
    updated: int
    object_: Literal["monitoring.endpoint"] | Unset = UNSET

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

        created = self.created

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "site_id": site_id,
                "user_id": user_id,
                "author_kind": author_kind,
                "author_id": author_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "kind": kind,
                "url": url,
                "expected_status": expected_status,
                "expected_body_contains": expected_body_contains,
                "timeout_ms": timeout_ms,
                "degraded_threshold_ms": degraded_threshold_ms,
                "check_interval_seconds": check_interval_seconds,
                "is_active": is_active,
                "created": created,
                "updated": updated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        site_id = d.pop("site_id")

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

        kind = d.pop("kind")

        url = d.pop("url")

        expected_status = d.pop("expected_status")

        def _parse_expected_body_contains(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        expected_body_contains = _parse_expected_body_contains(d.pop("expected_body_contains"))

        timeout_ms = d.pop("timeout_ms")

        degraded_threshold_ms = d.pop("degraded_threshold_ms")

        check_interval_seconds = d.pop("check_interval_seconds")

        is_active = d.pop("is_active")

        created = d.pop("created")

        updated = d.pop("updated")

        object_ = cast(Literal["monitoring.endpoint"] | Unset, d.pop("object", UNSET))
        if object_ != "monitoring.endpoint" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'monitoring.endpoint', got '{object_}'")

        get_v1_monitoring_endpoints_by_id_response_200 = cls(
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
            created=created,
            updated=updated,
            object_=object_,
        )

        return get_v1_monitoring_endpoints_by_id_response_200
