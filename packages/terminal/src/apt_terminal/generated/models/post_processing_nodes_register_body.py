from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.ai_processing_provider_kind import AiProcessingProviderKind
from ..models.post_processing_nodes_register_body_kind import PostProcessingNodesRegisterBodyKind

if TYPE_CHECKING:
    from ..models.post_processing_nodes_register_body_config import (
        PostProcessingNodesRegisterBodyConfig,
    )


T = TypeVar("T", bound="PostProcessingNodesRegisterBody")


@_attrs_define
class PostProcessingNodesRegisterBody:
    """
    Attributes:
        id (str): Stable node id
        kind (PostProcessingNodesRegisterBodyKind):
        version (str):
        host (str):
        providers (list[AiProcessingProviderKind]):
        config (PostProcessingNodesRegisterBodyConfig): Non-secret configuration the node reports; at most 8 KB
            serialized
    """

    id: str
    kind: PostProcessingNodesRegisterBodyKind
    version: str
    host: str
    providers: list[AiProcessingProviderKind]
    config: PostProcessingNodesRegisterBodyConfig
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
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_processing_nodes_register_body_config import (
            PostProcessingNodesRegisterBodyConfig,
        )

        d = dict(src_dict)
        id = d.pop("id")

        kind = PostProcessingNodesRegisterBodyKind(d.pop("kind"))

        version = d.pop("version")

        host = d.pop("host")

        providers = []
        _providers = d.pop("providers")
        for providers_item_data in _providers:
            providers_item = AiProcessingProviderKind(providers_item_data)

            providers.append(providers_item)

        config = PostProcessingNodesRegisterBodyConfig.from_dict(d.pop("config"))

        post_processing_nodes_register_body = cls(
            id=id,
            kind=kind,
            version=version,
            host=host,
            providers=providers,
            config=config,
        )

        post_processing_nodes_register_body.additional_properties = d
        return post_processing_nodes_register_body

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
