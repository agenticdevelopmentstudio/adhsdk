from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.integration_provider_config_config import IntegrationProviderConfigConfig
    from ..models.integration_provider_config_deliverability_webhook_type_0 import (
        IntegrationProviderConfigDeliverabilityWebhookType0,
    )


T = TypeVar("T", bound="IntegrationProviderConfig")


@_attrs_define
class IntegrationProviderConfig:
    """
    Attributes:
        id (UUID):
        ecosystem_id (str): Ecosystem id (the RLS owner)
        provider_id (str):
        name (str): Human-facing instance name (drives the rdid leaf)
        rdid (None | str): The reverse-domain id integration.<ecosystem-slug>.<name-slug> (addressable), or null when
            this row has no canonical mapping. NULLABLE RATHER THAN "" — the read paths attach the rdid with a second lookup
            that can legitimately come back empty (a row predating the mint, or one whose mapping an operator freed), and
            the empty string is a valid rdid-shaped value clients treat as one: keying rows on it collapses every unmapped
            config into a single identity. Fall back to `id` for row identity.
        config (IntegrationProviderConfigConfig): Non-secret config: clientId, scopes, URLs, endpoints, credentialStyle
        has_secret (bool): Whether a client secret is stored (the value is never returned)
        updated_by (None | str | Unset):
        created_at (str | Unset):
        updated_at (str | Unset):
        deliverability_webhook (IntegrationProviderConfigDeliverabilityWebhookType0 | None | Unset): Postmark
            deliverability webhook registration details (postmark configs only)
    """

    id: UUID
    ecosystem_id: str
    provider_id: str
    name: str
    rdid: None | str
    config: IntegrationProviderConfigConfig
    has_secret: bool
    updated_by: None | str | Unset = UNSET
    created_at: str | Unset = UNSET
    updated_at: str | Unset = UNSET
    deliverability_webhook: IntegrationProviderConfigDeliverabilityWebhookType0 | None | Unset = (
        UNSET
    )
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.integration_provider_config_deliverability_webhook_type_0 import (
            IntegrationProviderConfigDeliverabilityWebhookType0,
        )

        id = str(self.id)

        ecosystem_id = self.ecosystem_id

        provider_id = self.provider_id

        name = self.name

        rdid: None | str
        rdid = self.rdid

        config = self.config.to_dict()

        has_secret = self.has_secret

        updated_by: None | str | Unset
        if isinstance(self.updated_by, Unset):
            updated_by = UNSET
        else:
            updated_by = self.updated_by

        created_at = self.created_at

        updated_at = self.updated_at

        deliverability_webhook: dict[str, Any] | None | Unset
        if isinstance(self.deliverability_webhook, Unset):
            deliverability_webhook = UNSET
        elif isinstance(
            self.deliverability_webhook, IntegrationProviderConfigDeliverabilityWebhookType0
        ):
            deliverability_webhook = self.deliverability_webhook.to_dict()
        else:
            deliverability_webhook = self.deliverability_webhook

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "providerId": provider_id,
                "name": name,
                "rdid": rdid,
                "config": config,
                "hasSecret": has_secret,
            }
        )
        if updated_by is not UNSET:
            field_dict["updatedBy"] = updated_by
        if created_at is not UNSET:
            field_dict["createdAt"] = created_at
        if updated_at is not UNSET:
            field_dict["updatedAt"] = updated_at
        if deliverability_webhook is not UNSET:
            field_dict["deliverabilityWebhook"] = deliverability_webhook

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.integration_provider_config_config import (
            IntegrationProviderConfigConfig,
        )
        from ..models.integration_provider_config_deliverability_webhook_type_0 import (
            IntegrationProviderConfigDeliverabilityWebhookType0,
        )

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        ecosystem_id = d.pop("ecosystemId")

        provider_id = d.pop("providerId")

        name = d.pop("name")

        def _parse_rdid(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        rdid = _parse_rdid(d.pop("rdid"))

        config = IntegrationProviderConfigConfig.from_dict(d.pop("config"))

        has_secret = d.pop("hasSecret")

        def _parse_updated_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        updated_by = _parse_updated_by(d.pop("updatedBy", UNSET))

        created_at = d.pop("createdAt", UNSET)

        updated_at = d.pop("updatedAt", UNSET)

        def _parse_deliverability_webhook(
            data: object,
        ) -> IntegrationProviderConfigDeliverabilityWebhookType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                deliverability_webhook_type_0 = (
                    IntegrationProviderConfigDeliverabilityWebhookType0.from_dict(data)
                )

                return deliverability_webhook_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(IntegrationProviderConfigDeliverabilityWebhookType0 | None | Unset, data)

        deliverability_webhook = _parse_deliverability_webhook(
            d.pop("deliverabilityWebhook", UNSET)
        )

        integration_provider_config = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            provider_id=provider_id,
            name=name,
            rdid=rdid,
            config=config,
            has_secret=has_secret,
            updated_by=updated_by,
            created_at=created_at,
            updated_at=updated_at,
            deliverability_webhook=deliverability_webhook,
        )

        integration_provider_config.additional_properties = d
        return integration_provider_config

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
