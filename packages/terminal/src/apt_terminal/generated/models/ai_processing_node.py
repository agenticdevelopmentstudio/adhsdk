from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.ai_processing_node_kind import AiProcessingNodeKind
from ..models.ai_processing_provider_kind import AiProcessingProviderKind

if TYPE_CHECKING:
    from ..models.ai_processing_node_config import AiProcessingNodeConfig


T = TypeVar("T", bound="AiProcessingNode")


@_attrs_define
class AiProcessingNode:
    """
    Attributes:
        id (str):
        kind (AiProcessingNodeKind):
        version (str):
        host (str):
        providers (list[AiProcessingProviderKind]):
        config (AiProcessingNodeConfig): Reported, non-secret
        online (bool): last_seen_at is within the last 2 minutes
        first_seen_at (str):
        last_seen_at (str):
        jobs_completed (int):
        jobs_failed (int):
    """

    id: str
    kind: AiProcessingNodeKind
    version: str
    host: str
    providers: list[AiProcessingProviderKind]
    config: AiProcessingNodeConfig
    online: bool
    first_seen_at: str
    last_seen_at: str
    jobs_completed: int
    jobs_failed: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        kind = self.kind.value

        version = self.version

        host = self.host

        providers = []
        for providers_item_data in self.providers:
            providers_item = providers_item_data.value
            providers.append(providers_item)

        config = self.config.to_dict()

        online = self.online

        first_seen_at = self.first_seen_at

        last_seen_at = self.last_seen_at

        jobs_completed = self.jobs_completed

        jobs_failed = self.jobs_failed

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "kind": kind,
                "version": version,
                "host": host,
                "providers": providers,
                "config": config,
                "online": online,
                "first_seen_at": first_seen_at,
                "last_seen_at": last_seen_at,
                "jobs_completed": jobs_completed,
                "jobs_failed": jobs_failed,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ai_processing_node_config import AiProcessingNodeConfig

        d = dict(src_dict)
        id = d.pop("id")

        kind = AiProcessingNodeKind(d.pop("kind"))

        version = d.pop("version")

        host = d.pop("host")

        providers = []
        _providers = d.pop("providers")
        for providers_item_data in _providers:
            providers_item = AiProcessingProviderKind(providers_item_data)

            providers.append(providers_item)

        config = AiProcessingNodeConfig.from_dict(d.pop("config"))

        online = d.pop("online")

        first_seen_at = d.pop("first_seen_at")

        last_seen_at = d.pop("last_seen_at")

        jobs_completed = d.pop("jobs_completed")

        jobs_failed = d.pop("jobs_failed")

        ai_processing_node = cls(
            id=id,
            kind=kind,
            version=version,
            host=host,
            providers=providers,
            config=config,
            online=online,
            first_seen_at=first_seen_at,
            last_seen_at=last_seen_at,
            jobs_completed=jobs_completed,
            jobs_failed=jobs_failed,
        )

        ai_processing_node.additional_properties = d
        return ai_processing_node

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
