from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.ai_processing_config_set import AiProcessingConfigSet


T = TypeVar("T", bound="GetProcessingAdminConfigSetsResponse200")


@_attrs_define
class GetProcessingAdminConfigSetsResponse200:
    """
    Attributes:
        config_sets (list[AiProcessingConfigSet]):
    """

    config_sets: list[AiProcessingConfigSet]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        config_sets = []
        for config_sets_item_data in self.config_sets:
            config_sets_item = config_sets_item_data.to_dict()
            config_sets.append(config_sets_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "configSets": config_sets,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ai_processing_config_set import AiProcessingConfigSet

        d = dict(src_dict)
        config_sets = []
        _config_sets = d.pop("configSets")
        for config_sets_item_data in _config_sets:
            config_sets_item = AiProcessingConfigSet.from_dict(config_sets_item_data)

            config_sets.append(config_sets_item)

        get_processing_admin_config_sets_response_200 = cls(
            config_sets=config_sets,
        )

        get_processing_admin_config_sets_response_200.additional_properties = d
        return get_processing_admin_config_sets_response_200

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
