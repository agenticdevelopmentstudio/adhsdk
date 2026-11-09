from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="IntegrationProviderConfigDeliverabilityWebhookType0")


@_attrs_define
class IntegrationProviderConfigDeliverabilityWebhookType0:
    """Postmark deliverability webhook registration details (postmark configs only)

    Attributes:
        url (str): Absolute URL to paste into Postmark
        secret_header (str): Header Postmark must send this config's webhook secret in
        secret (None | str): This config's own inbound webhook secret. Never shared between ecosystems. Null when none
            has been minted yet (a config predating the feature) — POST .../rotate-webhook-secret mints one.
        instruction (str): One-line operator instruction
    """

    url: str
    secret_header: str
    secret: None | str
    instruction: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        url = self.url

        secret_header = self.secret_header

        secret: None | str
        secret = self.secret

        instruction = self.instruction

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "url": url,
                "secret_header": secret_header,
                "secret": secret,
                "instruction": instruction,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        url = d.pop("url")

        secret_header = d.pop("secret_header")

        def _parse_secret(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        secret = _parse_secret(d.pop("secret"))

        instruction = d.pop("instruction")

        integration_provider_config_deliverability_webhook_type_0 = cls(
            url=url,
            secret_header=secret_header,
            secret=secret,
            instruction=instruction,
        )

        integration_provider_config_deliverability_webhook_type_0.additional_properties = d
        return integration_provider_config_deliverability_webhook_type_0

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
