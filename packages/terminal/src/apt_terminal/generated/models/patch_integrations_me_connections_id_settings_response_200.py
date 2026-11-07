from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.patch_integrations_me_connections_id_settings_response_200_sync_settings import (
        PatchIntegrationsMeConnectionsIdSettingsResponse200SyncSettings,
    )


T = TypeVar("T", bound="PatchIntegrationsMeConnectionsIdSettingsResponse200")


@_attrs_define
class PatchIntegrationsMeConnectionsIdSettingsResponse200:
    """
    Attributes:
        ok (bool):
        sync_settings (PatchIntegrationsMeConnectionsIdSettingsResponse200SyncSettings):
    """

    ok: bool
    sync_settings: PatchIntegrationsMeConnectionsIdSettingsResponse200SyncSettings
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ok = self.ok

        sync_settings = self.sync_settings.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ok": ok,
                "syncSettings": sync_settings,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.patch_integrations_me_connections_id_settings_response_200_sync_settings import (
            PatchIntegrationsMeConnectionsIdSettingsResponse200SyncSettings,
        )

        d = dict(src_dict)
        ok = d.pop("ok")

        sync_settings = PatchIntegrationsMeConnectionsIdSettingsResponse200SyncSettings.from_dict(
            d.pop("syncSettings")
        )

        patch_integrations_me_connections_id_settings_response_200 = cls(
            ok=ok,
            sync_settings=sync_settings,
        )

        patch_integrations_me_connections_id_settings_response_200.additional_properties = d
        return patch_integrations_me_connections_id_settings_response_200

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
