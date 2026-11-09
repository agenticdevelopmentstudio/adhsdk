from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_integrations_campaign_stats_response_201_raw_type_0_type_1 import (
        PostV1IntegrationsCampaignStatsResponse201RawType0Type1,
    )


T = TypeVar("T", bound="PostV1IntegrationsCampaignStatsResponse201")


@_attrs_define
class PostV1IntegrationsCampaignStatsResponse201:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        owner_kind (str):
        owner_id (str):
        connection_id (str):
        provider (str):
        audience_id (str):
        external_id (str):
        name (None | str):
        subject (None | str):
        status (None | str):
        sent_at (None | str):
        recipients (int | None):
        opens (int | None):
        unique_opens (int | None):
        clicks (int | None):
        unique_clicks (int | None):
        bounces (int | None):
        unsubscribes (int | None):
        raw (bool | float | list[Any] | None | PostV1IntegrationsCampaignStatsResponse201RawType0Type1 | str):
        is_deleted (bool):
        deleted_at (None | str):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        author_kind (None | str):
        author_id (None | str):
        object_ (Literal['integrations.campaign_stat'] | Unset):
    """

    id: str
    ecosystem_id: str
    owner_kind: str
    owner_id: str
    connection_id: str
    provider: str
    audience_id: str
    external_id: str
    name: None | str
    subject: None | str
    status: None | str
    sent_at: None | str
    recipients: int | None
    opens: int | None
    unique_opens: int | None
    clicks: int | None
    unique_clicks: int | None
    bounces: int | None
    unsubscribes: int | None
    raw: (
        bool
        | float
        | list[Any]
        | None
        | PostV1IntegrationsCampaignStatsResponse201RawType0Type1
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
    object_: Literal["integrations.campaign_stat"] | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_v1_integrations_campaign_stats_response_201_raw_type_0_type_1 import (
            PostV1IntegrationsCampaignStatsResponse201RawType0Type1,
        )

        id = self.id

        ecosystem_id = self.ecosystem_id

        owner_kind = self.owner_kind

        owner_id = self.owner_id

        connection_id = self.connection_id

        provider = self.provider

        audience_id = self.audience_id

        external_id = self.external_id

        name: None | str
        name = self.name

        subject: None | str
        subject = self.subject

        status: None | str
        status = self.status

        sent_at: None | str
        sent_at = self.sent_at

        recipients: int | None
        recipients = self.recipients

        opens: int | None
        opens = self.opens

        unique_opens: int | None
        unique_opens = self.unique_opens

        clicks: int | None
        clicks = self.clicks

        unique_clicks: int | None
        unique_clicks = self.unique_clicks

        bounces: int | None
        bounces = self.bounces

        unsubscribes: int | None
        unsubscribes = self.unsubscribes

        raw: bool | dict[str, Any] | float | list[Any] | None | str
        if isinstance(self.raw, PostV1IntegrationsCampaignStatsResponse201RawType0Type1):
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
                "audience_id": audience_id,
                "external_id": external_id,
                "name": name,
                "subject": subject,
                "status": status,
                "sent_at": sent_at,
                "recipients": recipients,
                "opens": opens,
                "unique_opens": unique_opens,
                "clicks": clicks,
                "unique_clicks": unique_clicks,
                "bounces": bounces,
                "unsubscribes": unsubscribes,
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
        from ..models.post_v1_integrations_campaign_stats_response_201_raw_type_0_type_1 import (
            PostV1IntegrationsCampaignStatsResponse201RawType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        owner_kind = d.pop("owner_kind")

        owner_id = d.pop("owner_id")

        connection_id = d.pop("connection_id")

        provider = d.pop("provider")

        audience_id = d.pop("audience_id")

        external_id = d.pop("external_id")

        def _parse_name(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        name = _parse_name(d.pop("name"))

        def _parse_subject(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        subject = _parse_subject(d.pop("subject"))

        def _parse_status(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        status = _parse_status(d.pop("status"))

        def _parse_sent_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sent_at = _parse_sent_at(d.pop("sent_at"))

        def _parse_recipients(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        recipients = _parse_recipients(d.pop("recipients"))

        def _parse_opens(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        opens = _parse_opens(d.pop("opens"))

        def _parse_unique_opens(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        unique_opens = _parse_unique_opens(d.pop("unique_opens"))

        def _parse_clicks(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        clicks = _parse_clicks(d.pop("clicks"))

        def _parse_unique_clicks(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        unique_clicks = _parse_unique_clicks(d.pop("unique_clicks"))

        def _parse_bounces(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        bounces = _parse_bounces(d.pop("bounces"))

        def _parse_unsubscribes(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        unsubscribes = _parse_unsubscribes(d.pop("unsubscribes"))

        def _parse_raw(
            data: object,
        ) -> (
            bool
            | float
            | list[Any]
            | None
            | PostV1IntegrationsCampaignStatsResponse201RawType0Type1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                raw_type_0_type_1 = (
                    PostV1IntegrationsCampaignStatsResponse201RawType0Type1.from_dict(data)
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
                | PostV1IntegrationsCampaignStatsResponse201RawType0Type1
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

        object_ = cast(Literal["integrations.campaign_stat"] | Unset, d.pop("object", UNSET))
        if object_ != "integrations.campaign_stat" and not isinstance(object_, Unset):
            raise ValueError(
                f"object must match const 'integrations.campaign_stat', got '{object_}'"
            )

        post_v1_integrations_campaign_stats_response_201 = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            owner_kind=owner_kind,
            owner_id=owner_id,
            connection_id=connection_id,
            provider=provider,
            audience_id=audience_id,
            external_id=external_id,
            name=name,
            subject=subject,
            status=status,
            sent_at=sent_at,
            recipients=recipients,
            opens=opens,
            unique_opens=unique_opens,
            clicks=clicks,
            unique_clicks=unique_clicks,
            bounces=bounces,
            unsubscribes=unsubscribes,
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

        return post_v1_integrations_campaign_stats_response_201
