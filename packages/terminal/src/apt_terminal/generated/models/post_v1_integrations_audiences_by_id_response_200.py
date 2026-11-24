from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_integrations_audiences_by_id_response_200_raw_type_0_type_1 import (
        PostV1IntegrationsAudiencesByIdResponse200RawType0Type1,
    )


T = TypeVar("T", bound="PostV1IntegrationsAudiencesByIdResponse200")


@_attrs_define
class PostV1IntegrationsAudiencesByIdResponse200:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        connection_id (str):
        provider (str):
        external_id (str):
        name (str):
        member_count (int | None):
        raw (bool | float | list[Any] | None | PostV1IntegrationsAudiencesByIdResponse200RawType0Type1 | str):
        is_deleted (bool):
        deleted_at (None | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        author_kind (None | str):
        author_id (None | str):
        object_ (Literal['integrations.audience'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    connection_id: str
    provider: str
    external_id: str
    name: str
    member_count: int | None
    raw: (
        bool
        | float
        | list[Any]
        | None
        | PostV1IntegrationsAudiencesByIdResponse200RawType0Type1
        | str
    )
    is_deleted: bool
    deleted_at: None | str
    created: int
    updated: int
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    author_kind: None | str
    author_id: None | str
    object_: Literal["integrations.audience"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_integrations_audiences_by_id_response_200_raw_type_0_type_1 import (
            PostV1IntegrationsAudiencesByIdResponse200RawType0Type1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        connection_id = self.connection_id

        provider = self.provider

        external_id = self.external_id

        name = self.name

        member_count: int | None
        member_count = self.member_count

        raw: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.raw, PostV1IntegrationsAudiencesByIdResponse200RawType0Type1):
            raw = self.raw.to_dict()
        elif isinstance(self.raw, list):
            raw = self.raw

        else:
            raw = self.raw

        is_deleted = self.is_deleted

        deleted_at: None | str
        deleted_at = self.deleted_at

        created = self.created

        updated = self.updated

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        object_ = self.object_

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "owner_kind": owner_kind,
                "owner_id": owner_id,
                "connection_id": connection_id,
                "provider": provider,
                "external_id": external_id,
                "name": name,
                "member_count": member_count,
                "raw": raw,
                "is_deleted": is_deleted,
                "deleted_at": deleted_at,
                "created": created,
                "updated": updated,
                "sync_version": sync_version,
                "sync_stamped_at": sync_stamped_at,
                "sync_txid": sync_txid,
                "author_kind": author_kind,
                "author_id": author_id,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_integrations_audiences_by_id_response_200_raw_type_0_type_1 import (
            PostV1IntegrationsAudiencesByIdResponse200RawType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        connection_id = d.pop("connection_id")

        provider = d.pop("provider")

        external_id = d.pop("external_id")

        name = d.pop("name")

        def _parse_member_count(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        member_count = _parse_member_count(d.pop("member_count"))

        def _parse_raw(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1IntegrationsAudiencesByIdResponse200RawType0Type1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                raw_type_0_type_1 = (
                    PostV1IntegrationsAudiencesByIdResponse200RawType0Type1.from_dict(data)
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
                | PostV1IntegrationsAudiencesByIdResponse200RawType0Type1
                | str,
                data,
            )

        raw = _parse_raw(d.pop("raw"))

        is_deleted = d.pop("is_deleted")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at"))

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("sync_stamped_at"))

        sync_txid = d.pop("sync_txid")

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

        object_ = cast(Literal["integrations.audience"] | Unset, d.pop("object", UNSET))
        if object_ != "integrations.audience" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'integrations.audience', got '{object_}'")

        post_v1_integrations_audiences_by_id_response_200 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            connection_id=connection_id,
            provider=provider,
            external_id=external_id,
            name=name,
            member_count=member_count,
            raw=raw,
            is_deleted=is_deleted,
            deleted_at=deleted_at,
            created=created,
            updated=updated,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            author_kind=author_kind,
            author_id=author_id,
            object_=object_,
        )

        return post_v1_integrations_audiences_by_id_response_200
