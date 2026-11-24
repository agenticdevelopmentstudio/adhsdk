from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.appearance_settings_prefs_color_mode import AppearanceSettingsPrefsColorMode
from ..models.appearance_settings_prefs_contrast import AppearanceSettingsPrefsContrast
from ..models.appearance_settings_prefs_reduce_motion import AppearanceSettingsPrefsReduceMotion
from ..models.appearance_settings_prefs_spacing import AppearanceSettingsPrefsSpacing
from ..models.appearance_settings_prefs_text_size import AppearanceSettingsPrefsTextSize
from ..types import UNSET, Unset

T = TypeVar("T", bound="AppearanceSettingsPrefs")


@_attrs_define
class AppearanceSettingsPrefs:
    """Empty object when the user has never saved a preference (client defaults apply)

    Attributes:
        color_mode (AppearanceSettingsPrefsColorMode | Unset): The user's colour scheme; 'auto' follows the operating
            system
        reduce_motion (AppearanceSettingsPrefsReduceMotion | Unset):
        contrast (AppearanceSettingsPrefsContrast | Unset):
        text_size (AppearanceSettingsPrefsTextSize | Unset):
        spacing (AppearanceSettingsPrefsSpacing | Unset):
        focus_outlines (bool | Unset):
        underline_links (bool | Unset):
    """

    color_mode: AppearanceSettingsPrefsColorMode | Unset = UNSET
    reduce_motion: AppearanceSettingsPrefsReduceMotion | Unset = UNSET
    contrast: AppearanceSettingsPrefsContrast | Unset = UNSET
    text_size: AppearanceSettingsPrefsTextSize | Unset = UNSET
    spacing: AppearanceSettingsPrefsSpacing | Unset = UNSET
    focus_outlines: bool | Unset = UNSET
    underline_links: bool | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        color_mode: str | Unset = UNSET
        if not isinstance(self.color_mode, Unset):
            color_mode = self.color_mode.value

        reduce_motion: str | Unset = UNSET
        if not isinstance(self.reduce_motion, Unset):
            reduce_motion = self.reduce_motion.value

        contrast: str | Unset = UNSET
        if not isinstance(self.contrast, Unset):
            contrast = self.contrast.value

        text_size: str | Unset = UNSET
        if not isinstance(self.text_size, Unset):
            text_size = self.text_size.value

        spacing: str | Unset = UNSET
        if not isinstance(self.spacing, Unset):
            spacing = self.spacing.value

        focus_outlines = self.focus_outlines

        underline_links = self.underline_links

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if color_mode is not UNSET:
            field_dict["color_mode"] = color_mode
        if reduce_motion is not UNSET:
            field_dict["reduce_motion"] = reduce_motion
        if contrast is not UNSET:
            field_dict["contrast"] = contrast
        if text_size is not UNSET:
            field_dict["text_size"] = text_size
        if spacing is not UNSET:
            field_dict["spacing"] = spacing
        if focus_outlines is not UNSET:
            field_dict["focus_outlines"] = focus_outlines
        if underline_links is not UNSET:
            field_dict["underline_links"] = underline_links

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        _color_mode = d.pop("color_mode", UNSET)
        color_mode: AppearanceSettingsPrefsColorMode | Unset
        if isinstance(_color_mode, Unset):
            color_mode = UNSET
        else:
            color_mode = AppearanceSettingsPrefsColorMode(_color_mode)

        _reduce_motion = d.pop("reduce_motion", UNSET)
        reduce_motion: AppearanceSettingsPrefsReduceMotion | Unset
        if isinstance(_reduce_motion, Unset):
            reduce_motion = UNSET
        else:
            reduce_motion = AppearanceSettingsPrefsReduceMotion(_reduce_motion)

        _contrast = d.pop("contrast", UNSET)
        contrast: AppearanceSettingsPrefsContrast | Unset
        if isinstance(_contrast, Unset):
            contrast = UNSET
        else:
            contrast = AppearanceSettingsPrefsContrast(_contrast)

        _text_size = d.pop("text_size", UNSET)
        text_size: AppearanceSettingsPrefsTextSize | Unset
        if isinstance(_text_size, Unset):
            text_size = UNSET
        else:
            text_size = AppearanceSettingsPrefsTextSize(_text_size)

        _spacing = d.pop("spacing", UNSET)
        spacing: AppearanceSettingsPrefsSpacing | Unset
        if isinstance(_spacing, Unset):
            spacing = UNSET
        else:
            spacing = AppearanceSettingsPrefsSpacing(_spacing)

        focus_outlines = d.pop("focus_outlines", UNSET)

        underline_links = d.pop("underline_links", UNSET)

        appearance_settings_prefs = cls(
            color_mode=color_mode,
            reduce_motion=reduce_motion,
            contrast=contrast,
            text_size=text_size,
            spacing=spacing,
            focus_outlines=focus_outlines,
            underline_links=underline_links,
        )

        appearance_settings_prefs.additional_properties = d
        return appearance_settings_prefs

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
