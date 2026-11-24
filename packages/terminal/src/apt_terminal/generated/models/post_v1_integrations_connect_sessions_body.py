from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_integrations_connect_sessions_body_flow import (
    PostV1IntegrationsConnectSessionsBodyFlow,
)
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1IntegrationsConnectSessionsBody")


@_attrs_define
class PostV1IntegrationsConnectSessionsBody:
    """
    Attributes:
        flow (PostV1IntegrationsConnectSessionsBodyFlow): Selects which kind of object this call works on.
        provider (str | Unset): Scopes the call; the caller passes it as a parameter, not in the path.
    """

    flow: PostV1IntegrationsConnectSessionsBodyFlow
    provider: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        flow = self.flow.value

        provider = self.provider

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "flow": flow,
            }
        )
        if provider is not UNSET:
            field_dict["provider"] = provider

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        flow = PostV1IntegrationsConnectSessionsBodyFlow(d.pop("flow"))

        provider = d.pop("provider", UNSET)

        post_v1_integrations_connect_sessions_body = cls(
            flow=flow,
            provider=provider,
        )

        post_v1_integrations_connect_sessions_body.additional_properties = d
        return post_v1_integrations_connect_sessions_body

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
