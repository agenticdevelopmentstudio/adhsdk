from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_integrations_audiences_by_id_body_raw_type_0_type_1 import (
        PostV1IntegrationsAudiencesByIdBodyRawType0Type1,
    )


T = TypeVar("T", bound="PostV1IntegrationsAudiencesByIdBody")


@_attrs_define
class PostV1IntegrationsAudiencesByIdBody:
    """
    Attributes:
        ecosystem_id (str | Unset):
        connection_id (str | Unset):
        provider (str | Unset):
        external_id (str | Unset):
        name (str | Unset):
        member_count (int | None | Unset):
        raw (bool | float | list[Any] | None | PostV1IntegrationsAudiencesByIdBodyRawType0Type1 | str | Unset):
    """

    ecosystem_id: str | Unset = UNSET
    connection_id: str | Unset = UNSET
    provider: str | Unset = UNSET
    external_id: str | Unset = UNSET
    name: str | Unset = UNSET
    member_count: int | None | Unset = UNSET
    raw: (
        bool
        | float
        | list[Any]
        | None
        | PostV1IntegrationsAudiencesByIdBodyRawType0Type1
        | str
        | Unset
    ) = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_integrations_audiences_by_id_body_raw_type_0_type_1 import (
            PostV1IntegrationsAudiencesByIdBodyRawType0Type1,
        )

        ecosystem_id = self.ecosystem_id

        connection_id = self.connection_id

        provider = self.provider

        external_id = self.external_id

        name = self.name

        member_count: int | None | Unset
        if isinstance(self.member_count, Unset):
            member_count = UNSET
        else:
            member_count = self.member_count

        raw: bool | dict[str, Any] | float | list[Any] | None | str | Unset
        if isinstance(self.raw, Unset):
            raw = UNSET
        elif isinstance(self.raw, PostV1IntegrationsAudiencesByIdBodyRawType0Type1):
            raw = self.raw.to_dict()
        elif isinstance(self.raw, list):
            raw = self.raw

        else:
            raw = self.raw

        field_dict: dict[str, Any] = {}

        field_dict.update({})
        if ecosystem_id is not UNSET:
            field_dict["ecosystem_id"] = ecosystem_id
        if connection_id is not UNSET:
            field_dict["connection_id"] = connection_id
        if provider is not UNSET:
            field_dict["provider"] = provider
        if external_id is not UNSET:
            field_dict["external_id"] = external_id
        if name is not UNSET:
            field_dict["name"] = name
        if member_count is not UNSET:
            field_dict["member_count"] = member_count
        if raw is not UNSET:
            field_dict["raw"] = raw

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_integrations_audiences_by_id_body_raw_type_0_type_1 import (
            PostV1IntegrationsAudiencesByIdBodyRawType0Type1,
        )

        d = dict(src_dict)
        ecosystem_id = d.pop("ecosystem_id", UNSET)

        connection_id = d.pop("connection_id", UNSET)

        provider = d.pop("provider", UNSET)

        external_id = d.pop("external_id", UNSET)

        name = d.pop("name", UNSET)

        def _parse_member_count(data: object) -> int | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(int | None | Unset, data)

        member_count = _parse_member_count(d.pop("member_count", UNSET))

        def _parse_raw(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1IntegrationsAudiencesByIdBodyRawType0Type1
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
                raw_type_0_type_1 = PostV1IntegrationsAudiencesByIdBodyRawType0Type1.from_dict(data)

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
                | PostV1IntegrationsAudiencesByIdBodyRawType0Type1
                | str
                | Unset,
                data,
            )

        raw = _parse_raw(d.pop("raw", UNSET))

        post_v1_integrations_audiences_by_id_body = cls(
            ecosystem_id=ecosystem_id,
            connection_id=connection_id,
            provider=provider,
            external_id=external_id,
            name=name,
            member_count=member_count,
            raw=raw,
        )

        return post_v1_integrations_audiences_by_id_body
