from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define

if TYPE_CHECKING:
    from ..models.post_integration_integration_campaign_stats_response_201_raw_type_0_type_1 import (
        PostIntegrationIntegrationCampaignStatsResponse201RawType0Type1,
    )


T = TypeVar("T", bound="PostIntegrationIntegrationCampaignStatsResponse201")


@_attrs_define
class PostIntegrationIntegrationCampaignStatsResponse201:
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
        raw (bool | float | list[Any] | None | PostIntegrationIntegrationCampaignStatsResponse201RawType0Type1 | str):
        is_deleted (bool):
        deleted_at (None | str):
        created_at (str):
        updated_at (str):
        sync_version (int):
        sync_stamped_at (None | str):
        sync_txid (int):
        author_kind (None | str):
        author_id (None | str):
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
        | PostIntegrationIntegrationCampaignStatsResponse201RawType0Type1
        | str
    )
    is_deleted: bool
    deleted_at: None | str
    created_at: str
    updated_at: str
    sync_version: int
    sync_stamped_at: None | str
    sync_txid: int
    author_kind: None | str
    author_id: None | str

    def to_dict(self) -> dict[str, Any]:
        from ..models.post_integration_integration_campaign_stats_response_201_raw_type_0_type_1 import (
            PostIntegrationIntegrationCampaignStatsResponse201RawType0Type1,
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
        if isinstance(self.raw, PostIntegrationIntegrationCampaignStatsResponse201RawType0Type1):
            raw = self.raw.to_dict()
        elif isinstance(self.raw, list):
            raw = self.raw

        else:
            raw = self.raw

        is_deleted = self.is_deleted

        deleted_at: None | str
        deleted_at = self.deleted_at

        created_at = self.created_at

        updated_at = self.updated_at

        sync_version = self.sync_version

        sync_stamped_at: None | str
        sync_stamped_at = self.sync_stamped_at

        sync_txid = self.sync_txid

        author_kind: None | str
        author_kind = self.author_kind

        author_id: None | str
        author_id = self.author_id

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "ownerKind": owner_kind,
                "ownerId": owner_id,
                "connectionId": connection_id,
                "provider": provider,
                "audienceId": audience_id,
                "externalId": external_id,
                "name": name,
                "subject": subject,
                "status": status,
                "sentAt": sent_at,
                "recipients": recipients,
                "opens": opens,
                "uniqueOpens": unique_opens,
                "clicks": clicks,
                "uniqueClicks": unique_clicks,
                "bounces": bounces,
                "unsubscribes": unsubscribes,
                "raw": raw,
                "isDeleted": is_deleted,
                "deletedAt": deleted_at,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "syncVersion": sync_version,
                "syncStampedAt": sync_stamped_at,
                "syncTxid": sync_txid,
                "authorKind": author_kind,
                "authorId": author_id,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_integration_integration_campaign_stats_response_201_raw_type_0_type_1 import (
            PostIntegrationIntegrationCampaignStatsResponse201RawType0Type1,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        owner_kind = d.pop("ownerKind")

        owner_id = d.pop("ownerId")

        connection_id = d.pop("connectionId")

        provider = d.pop("provider")

        audience_id = d.pop("audienceId")

        external_id = d.pop("externalId")

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

        sent_at = _parse_sent_at(d.pop("sentAt"))

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

        unique_opens = _parse_unique_opens(d.pop("uniqueOpens"))

        def _parse_clicks(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        clicks = _parse_clicks(d.pop("clicks"))

        def _parse_unique_clicks(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        unique_clicks = _parse_unique_clicks(d.pop("uniqueClicks"))

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
            | PostIntegrationIntegrationCampaignStatsResponse201RawType0Type1
            | str
        ):
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                raw_type_0_type_1 = (
                    PostIntegrationIntegrationCampaignStatsResponse201RawType0Type1.from_dict(data)
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
                | PostIntegrationIntegrationCampaignStatsResponse201RawType0Type1
                | str,
                data,
            )

        raw = _parse_raw(d.pop("raw"))

        is_deleted = d.pop("isDeleted")

        def _parse_deleted_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt"))

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_sync_stamped_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        sync_stamped_at = _parse_sync_stamped_at(d.pop("syncStampedAt"))

        sync_txid = d.pop("syncTxid")

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

        post_integration_integration_campaign_stats_response_201 = cls(
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
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            sync_stamped_at=sync_stamped_at,
            sync_txid=sync_txid,
            author_kind=author_kind,
            author_id=author_id,
        )

        return post_integration_integration_campaign_stats_response_201
