from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="GetIntegrationsEndUserConnectionsResponse200ConnectionsItem")


@_attrs_define
class GetIntegrationsEndUserConnectionsResponse200ConnectionsItem:
    """
    Attributes:
        provider (str):
        service_type (str):
        status (str): active | error | revoked | pending
        last_sync_at (None | str):
        last_error (None | str):
    """

    provider: str
    service_type: str
    status: str
    last_sync_at: None | str
    last_error: None | str
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        provider = self.provider

        service_type = self.service_type

        status = self.status

        last_sync_at: None | str
        last_sync_at = self.last_sync_at

        last_error: None | str
        last_error = self.last_error

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "provider": provider,
                "serviceType": service_type,
                "status": status,
                "lastSyncAt": last_sync_at,
                "lastError": last_error,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        provider = d.pop("provider")

        service_type = d.pop("serviceType")

        status = d.pop("status")

        def _parse_last_sync_at(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_sync_at = _parse_last_sync_at(d.pop("lastSyncAt"))

        def _parse_last_error(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        last_error = _parse_last_error(d.pop("lastError"))

        get_integrations_end_user_connections_response_200_connections_item = cls(
            provider=provider,
            service_type=service_type,
            status=status,
            last_sync_at=last_sync_at,
            last_error=last_error,
        )

        get_integrations_end_user_connections_response_200_connections_item.additional_properties = d
        return get_integrations_end_user_connections_response_200_connections_item

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
