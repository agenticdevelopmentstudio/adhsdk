from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_v1_integrations_connections_by_id_response_200_sync_settings import (
        PostV1IntegrationsConnectionsByIdResponse200SyncSettings,
    )


T = TypeVar("T", bound="PostV1IntegrationsConnectionsByIdResponse200")


@_attrs_define
class PostV1IntegrationsConnectionsByIdResponse200:
    """
    Attributes:
        ok (bool):
        sync_settings (PostV1IntegrationsConnectionsByIdResponse200SyncSettings):
        object_ (Literal['integrations.connection'] | Unset):
    """

    ok: bool
    sync_settings: PostV1IntegrationsConnectionsByIdResponse200SyncSettings
    object_: Literal["integrations.connection"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        ok = self.ok

        sync_settings = self.sync_settings.to_dict()

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "ok": ok,
                "sync_settings": sync_settings,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_v1_integrations_connections_by_id_response_200_sync_settings import (
            PostV1IntegrationsConnectionsByIdResponse200SyncSettings,
        )

        d = dict(src_dict)
        ok = d.pop("ok")

        sync_settings = PostV1IntegrationsConnectionsByIdResponse200SyncSettings.from_dict(
            d.pop("sync_settings")
        )

        object_ = cast(Literal["integrations.connection"] | Unset, d.pop("object", UNSET))
        if object_ != "integrations.connection" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'integrations.connection', got '{object_}'")

        post_v1_integrations_connections_by_id_response_200 = cls(
            ok=ok,
            sync_settings=sync_settings,
            object_=object_,
        )

        post_v1_integrations_connections_by_id_response_200.additional_properties = d
        return post_v1_integrations_connections_by_id_response_200

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
