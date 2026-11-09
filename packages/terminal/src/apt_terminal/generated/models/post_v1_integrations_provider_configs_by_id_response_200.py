from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.integration_global_config_config import IntegrationGlobalConfigConfig


T = TypeVar("T", bound="PostV1IntegrationsProviderConfigsByIdResponse200")


@_attrs_define
class PostV1IntegrationsProviderConfigsByIdResponse200:
    """
    Attributes:
        provider_id (str):
        config (IntegrationGlobalConfigConfig): Non-secret config: clientId, scopes, URLs, endpoints, credentialStyle
        has_secret (bool): Whether a client secret is stored (the value is never returned)
        updated_by (None | str | Unset):
        updated (int | Unset): Unix timestamp, in seconds.
        object_ (Literal['integrations.provider_config'] | Unset):
    """

    provider_id: str
    config: IntegrationGlobalConfigConfig
    has_secret: bool
    updated_by: None | str | Unset = UNSET
    updated: int | Unset = UNSET
    object_: Literal["integrations.provider_config"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        provider_id = self.provider_id

        config = self.config.to_dict()

        has_secret = self.has_secret

        updated_by: None | str | Unset
        if isinstance(self.updated_by, Unset):
            updated_by = UNSET
        else:
            updated_by = self.updated_by

        updated = self.updated

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "provider_id": provider_id,
                "config": config,
                "has_secret": has_secret,
            }
        )
        if updated_by is not UNSET:
            field_dict["updated_by"] = updated_by
        if updated is not UNSET:
            field_dict["updated"] = updated
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.integration_global_config_config import (
            IntegrationGlobalConfigConfig,
        )

        d = dict(src_dict)
        provider_id = d.pop("provider_id")

        config = IntegrationGlobalConfigConfig.from_dict(d.pop("config"))

        has_secret = d.pop("has_secret")

        def _parse_updated_by(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        updated_by = _parse_updated_by(d.pop("updated_by", UNSET))

        updated = d.pop("updated", UNSET)

        object_ = cast(Literal["integrations.provider_config"] | Unset, d.pop("object", UNSET))
        if object_ != "integrations.provider_config" and not isinstance(object_, Unset):
            raise ValueError(
                f"object must match const 'integrations.provider_config', got '{object_}'"
            )

        post_v1_integrations_provider_configs_by_id_response_200 = cls(
            provider_id=provider_id,
            config=config,
            has_secret=has_secret,
            updated_by=updated_by,
            updated=updated,
            object_=object_,
        )

        post_v1_integrations_provider_configs_by_id_response_200.additional_properties = d
        return post_v1_integrations_provider_configs_by_id_response_200

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
