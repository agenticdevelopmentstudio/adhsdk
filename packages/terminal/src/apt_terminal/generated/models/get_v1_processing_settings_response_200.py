from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1ProcessingSettingsResponse200")


@_attrs_define
class GetV1ProcessingSettingsResponse200:
    """
    Attributes:
        log_retention_days (int):
        object_ (Literal['processing.settings'] | Unset):
    """

    log_retention_days: int
    object_: Literal["processing.settings"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        log_retention_days = self.log_retention_days

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "log_retention_days": log_retention_days,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        log_retention_days = d.pop("log_retention_days")

        object_ = cast(Literal["processing.settings"] | Unset, d.pop("object", UNSET))
        if object_ != "processing.settings" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'processing.settings', got '{object_}'")

        get_v1_processing_settings_response_200 = cls(
            log_retention_days=log_retention_days,
            object_=object_,
        )

        get_v1_processing_settings_response_200.additional_properties = d
        return get_v1_processing_settings_response_200

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
