from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_integration_integration_audiences_body_raw_type_0_type_1 import (
        PostIntegrationIntegrationAudiencesBodyRawType0Type1,
    )


T = TypeVar("T", bound="PostIntegrationIntegrationAudiencesBody")


@_attrs_define
class PostIntegrationIntegrationAudiencesBody:
    """
    Attributes:
        connection_id (str):
        provider (str):
        external_id (str):
        name (str):
        ecosystem_id (str | Unset):
        member_count (int | None | Unset):
        raw (bool | float | list[Any] | None | PostIntegrationIntegrationAudiencesBodyRawType0Type1 | str | Unset):
    """

    connection_id: str
    provider: str
    external_id: str
    name: str
    ecosystem_id: str | Unset = UNSET
    member_count: int | None | Unset = UNSET
    raw: (
        bool
        | float
        | list[Any]
        | None
        | PostIntegrationIntegrationAudiencesBodyRawType0Type1
        | str
        | Unset
    ) = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_integration_integration_audiences_body_raw_type_0_type_1 import (
            PostIntegrationIntegrationAudiencesBodyRawType0Type1,
        )

        connection_id = self.connection_id

        provider = self.provider

        external_id = self.external_id

        name = self.name

        ecosystem_id = self.ecosystem_id

        member_count: int | None | Unset
        if isinstance(self.member_count, Unset):
            member_count = UNSET
        else:
            member_count = self.member_count

        raw: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.raw, Unset):
            raw = UNSET
        elif isinstance(self.raw, PostIntegrationIntegrationAudiencesBodyRawType0Type1):
            raw = self.raw.to_dict()
        elif isinstance(self.raw, list):
            raw = self.raw

        else:
            raw = self.raw

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "connectionId": connection_id,
                "provider": provider,
                "externalId": external_id,
                "name": name,
            }
        )
        if ecosystem_id is not UNSET:
            field_dict["ecosystemId"] = ecosystem_id
        if member_count is not UNSET:
            field_dict["memberCount"] = member_count
        if raw is not UNSET:
            field_dict["raw"] = raw

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_integration_integration_audiences_body_raw_type_0_type_1 import (
            PostIntegrationIntegrationAudiencesBodyRawType0Type1,
        )

        d = dict(src_dict)
        connection_id = d.pop("connectionId")

        provider = d.pop("provider")

        external_id = d.pop("externalId")

        name = d.pop("name")

        ecosystem_id = d.pop("ecosystemId", UNSET)

        def _parse_member_count(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        member_count = _parse_member_count(d.pop("memberCount", UNSET))

        def _parse_raw(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostIntegrationIntegrationAudiencesBodyRawType0Type1
            | str
            | Unset
        ):
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                raw_type_0_type_1 = PostIntegrationIntegrationAudiencesBodyRawType0Type1.from_dict(
                    data
                )

                return raw_type_0_type_1
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            try:
                if not isinstance(data, list):
                    raise TypeError()
                raw_type_0_type_2 = cast(list[Any], data)

                return raw_type_0_type_2
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(
                bool
                | float
                | list[Any]
                | None
                | PostIntegrationIntegrationAudiencesBodyRawType0Type1
                | str
                | Unset,
                data,
            )

        raw = _parse_raw(d.pop("raw", UNSET))

        post_integration_integration_audiences_body = cls(
            connection_id=connection_id,
            provider=provider,
            external_id=external_id,
            name=name,
            ecosystem_id=ecosystem_id,
            member_count=member_count,
            raw=raw,
        )

        return post_integration_integration_audiences_body
