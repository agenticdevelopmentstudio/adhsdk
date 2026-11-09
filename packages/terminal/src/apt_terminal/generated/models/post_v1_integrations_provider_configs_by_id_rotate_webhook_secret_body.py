from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretBody")


@_attrs_define
class PostV1IntegrationsProviderConfigsByIdRotateWebhookSecretBody:
    """
    Attributes:
        ecosystem (str): Scopes the call; the caller passes it as a parameter, not in the path.
    """

    ecosystem: str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ecosystem = self.ecosystem

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ecosystem": ecosystem,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        ecosystem = d.pop("ecosystem")

        post_v1_integrations_provider_configs_by_id_rotate_webhook_secret_body = cls(
            ecosystem=ecosystem,
        )

        post_v1_integrations_provider_configs_by_id_rotate_webhook_secret_body.additional_properties = d
        return post_v1_integrations_provider_configs_by_id_rotate_webhook_secret_body

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
