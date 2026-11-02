from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.appearance_settings_prefs import AppearanceSettingsPrefs


T = TypeVar("T", bound="AppearanceSettings")


@_attrs_define
class AppearanceSettings:
    """
    Attributes:
        prefs (AppearanceSettingsPrefs): Empty object when the user has never saved a preference (client defaults apply)
    """

    prefs: AppearanceSettingsPrefs
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        prefs = self.prefs.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "prefs": prefs,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.appearance_settings_prefs import AppearanceSettingsPrefs

        d = dict(src_dict)
        prefs = AppearanceSettingsPrefs.from_dict(d.pop("prefs"))

        appearance_settings = cls(
            prefs=prefs,
        )

        appearance_settings.additional_properties = d
        return appearance_settings

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
