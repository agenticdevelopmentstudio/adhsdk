from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.template_sync_keys_type_0 import TemplateSyncKeysType0


T = TypeVar("T", bound="GetV1ProviderTemplatesByIdResponse200SyncKeys")


@_attrs_define
class GetV1ProviderTemplatesByIdResponse200SyncKeys:
    """
    Attributes:
        sync_keys (None | TemplateSyncKeysType0): Operator-only upstream sync mapping — never present on public reads.
    """

    sync_keys: None | TemplateSyncKeysType0
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.template_sync_keys_type_0 import TemplateSyncKeysType0

        sync_keys: dict[str, Any] | None
        if isinstance(self.sync_keys, TemplateSyncKeysType0):
            sync_keys = self.sync_keys.to_dict()
        else:
            sync_keys = self.sync_keys

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "sync_keys": sync_keys,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.template_sync_keys_type_0 import TemplateSyncKeysType0

        d = dict(src_dict)

        def _parse_sync_keys(data: object) -> None | TemplateSyncKeysType0:
            if data is None:
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                componentsschemas_template_sync_keys_type_0 = TemplateSyncKeysType0.from_dict(data)

                return componentsschemas_template_sync_keys_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | TemplateSyncKeysType0, data)

        sync_keys = _parse_sync_keys(d.pop("sync_keys"))

        get_v1_provider_templates_by_id_response_200_sync_keys = cls(
            sync_keys=sync_keys,
        )

        get_v1_provider_templates_by_id_response_200_sync_keys.additional_properties = d
        return get_v1_provider_templates_by_id_response_200_sync_keys

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
