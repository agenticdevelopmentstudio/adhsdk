from __future__ import annotations

import datetime
from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.job_environment_kind import JobEnvironmentKind

if TYPE_CHECKING:
    from ..models.job_environment_capabilities import JobEnvironmentCapabilities


T = TypeVar("T", bound="JobEnvironmentWithToken")


@_attrs_define
class JobEnvironmentWithToken:
    """
    Attributes:
        id (UUID):
        name (str):
        kind (JobEnvironmentKind):
        capabilities (JobEnvironmentCapabilities):
        last_seen_at (datetime.datetime | None):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        token (str): The `jenv_` token, shown only in this answer.
    """

    id: UUID
    name: str
    kind: JobEnvironmentKind
    capabilities: JobEnvironmentCapabilities
    last_seen_at: datetime.datetime | None
    created: int
    updated: int
    token: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        name = self.name

        kind = self.kind.value

        capabilities = self.capabilities.to_dict()

        last_seen_at: None | str
        if isinstance(self.last_seen_at, datetime.datetime):
            last_seen_at = self.last_seen_at.isoformat()
        else:
            last_seen_at = self.last_seen_at

        created = self.created

        updated = self.updated

        token = self.token

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "name": name,
                "kind": kind,
                "capabilities": capabilities,
                "last_seen_at": last_seen_at,
                "created": created,
                "updated": updated,
                "token": token,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.job_environment_capabilities import (
            JobEnvironmentCapabilities,
        )

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        name = d.pop("name")

        kind = JobEnvironmentKind(d.pop("kind"))

        capabilities = JobEnvironmentCapabilities.from_dict(d.pop("capabilities"))

        def _parse_last_seen_at(data: object) -> datetime.datetime | None:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                last_seen_at_type_0 = datetime.datetime.fromisoformat(data)

                return last_seen_at_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(datetime.datetime | None, data)

        last_seen_at = _parse_last_seen_at(d.pop("last_seen_at"))

        created = d.pop("created")

        updated = d.pop("updated")

        token = d.pop("token")

        job_environment_with_token = cls(
            id=id,
            name=name,
            kind=kind,
            capabilities=capabilities,
            last_seen_at=last_seen_at,
            created=created,
            updated=updated,
            token=token,
        )

        job_environment_with_token.additional_properties = d
        return job_environment_with_token

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
