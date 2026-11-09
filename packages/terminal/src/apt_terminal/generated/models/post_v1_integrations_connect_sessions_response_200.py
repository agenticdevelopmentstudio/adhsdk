from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.integration_connection_sync_settings_type_0 import (
        IntegrationConnectionSyncSettingsType0,
    )


T = TypeVar("T", bound="PostV1IntegrationsConnectSessionsResponse200")


@_attrs_define
class PostV1IntegrationsConnectSessionsResponse200:
    """
    Attributes:
        id (UUID):
        provider (str): Provider slug (e.g. google-calendar, github)
        service_type (str): Service within the provider (e.g. calendar)
        status (str): active | error | revoked | pending
        display_name (str):
        username (str):
        external_account_id (str): Provider-side account id
        created (int): Unix timestamp, in seconds.
        last_sync_at (None | str | Unset): Last successful sync (null = never)
        last_error (None | str | Unset): Last recorded sync error
        sync_settings (IntegrationConnectionSyncSettingsType0 | None | Unset): Caller-tunable sync settings
            (gmailLabelIds / redditSubreddits / …) — non-secret, returned so settings forms can prefill instead of blind-
            overwriting.
        object_ (Literal['integrations.connect_session'] | Unset):
    """

    id: UUID
    provider: str
    service_type: str
    status: str
    display_name: str
    username: str
    external_account_id: str
    created: int
    last_sync_at: None | str | Unset = UNSET
    last_error: None | str | Unset = UNSET
    sync_settings: IntegrationConnectionSyncSettingsType0 | None | Unset = UNSET
    object_: Literal["integrations.connect_session"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.integration_connection_sync_settings_type_0 import (
            IntegrationConnectionSyncSettingsType0,
        )

        id = str(self.id)

        provider = self.provider

        service_type = self.service_type

        status = self.status

        display_name = self.display_name

        username = self.username

        external_account_id = self.external_account_id

        created = self.created

        last_sync_at: None | str | Unset
        if isinstance(self.last_sync_at, Unset):
            last_sync_at = UNSET
        else:
            last_sync_at = self.last_sync_at

        last_error: None | str | Unset
        if isinstance(self.last_error, Unset):
            last_error = UNSET
        else:
            last_error = self.last_error

        sync_settings: dict[str, Any] | None | Unset
        if isinstance(self.sync_settings, Unset):
            sync_settings = UNSET
        elif isinstance(self.sync_settings, IntegrationConnectionSyncSettingsType0):
            sync_settings = self.sync_settings.to_dict()
        else:
            sync_settings = self.sync_settings

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "provider": provider,
                "service_type": service_type,
                "status": status,
                "display_name": display_name,
                "username": username,
                "external_account_id": external_account_id,
                "created": created,
            }
        )
        if last_sync_at is not UNSET:
            field_dict["last_sync_at"] = last_sync_at
        if last_error is not UNSET:
            field_dict["last_error"] = last_error
        if sync_settings is not UNSET:
            field_dict["sync_settings"] = sync_settings
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.integration_connection_sync_settings_type_0 import (
            IntegrationConnectionSyncSettingsType0,
        )

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        provider = d.pop("provider")

        service_type = d.pop("service_type")

        status = d.pop("status")

        display_name = d.pop("display_name")

        username = d.pop("username")

        external_account_id = d.pop("external_account_id")

        created = d.pop("created")

        def _parse_last_sync_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_sync_at = _parse_last_sync_at(d.pop("last_sync_at", UNSET))

        def _parse_last_error(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        last_error = _parse_last_error(d.pop("last_error", UNSET))

        def _parse_sync_settings(
            data: object,
        ) -> IntegrationConnectionSyncSettingsType0 | None | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                sync_settings_type_0 = IntegrationConnectionSyncSettingsType0.from_dict(data)

                return sync_settings_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(IntegrationConnectionSyncSettingsType0 | None | Unset, data)

        sync_settings = _parse_sync_settings(d.pop("sync_settings", UNSET))

        object_ = cast(Literal["integrations.connect_session"] | Unset, d.pop("object", UNSET))
        if object_ != "integrations.connect_session" and not isinstance(object_, Unset):
            raise ValueError(
                f"object must match const 'integrations.connect_session', got '{object_}'"
            )

        post_v1_integrations_connect_sessions_response_200 = cls(
            id=id,
            provider=provider,
            service_type=service_type,
            status=status,
            display_name=display_name,
            username=username,
            external_account_id=external_account_id,
            created=created,
            last_sync_at=last_sync_at,
            last_error=last_error,
            sync_settings=sync_settings,
            object_=object_,
        )

        post_v1_integrations_connect_sessions_response_200.additional_properties = d
        return post_v1_integrations_connect_sessions_response_200

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
