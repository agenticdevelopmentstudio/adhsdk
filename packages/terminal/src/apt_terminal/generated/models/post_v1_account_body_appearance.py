from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_account_body_appearance_color_mode import PostV1AccountBodyAppearanceColorMode
from ..models.post_v1_account_body_appearance_contrast import PostV1AccountBodyAppearanceContrast
from ..models.post_v1_account_body_appearance_reduce_motion import (
    PostV1AccountBodyAppearanceReduceMotion,
)
from ..models.post_v1_account_body_appearance_spacing import PostV1AccountBodyAppearanceSpacing
from ..models.post_v1_account_body_appearance_text_size import PostV1AccountBodyAppearanceTextSize
from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AccountBodyAppearance")


@_attrs_define
class PostV1AccountBodyAppearance:
    """Updates `appearance`.

    Attributes:
        color_mode (PostV1AccountBodyAppearanceColorMode | Unset): The user's colour scheme; 'auto' follows the
            operating system
        reduce_motion (PostV1AccountBodyAppearanceReduceMotion | Unset):
        contrast (PostV1AccountBodyAppearanceContrast | Unset):
        text_size (PostV1AccountBodyAppearanceTextSize | Unset):
        spacing (PostV1AccountBodyAppearanceSpacing | Unset):
        focus_outlines (bool | Unset):
        underline_links (bool | Unset):
    """

    color_mode: PostV1AccountBodyAppearanceColorMode | Unset = UNSET
    reduce_motion: PostV1AccountBodyAppearanceReduceMotion | Unset = UNSET
    contrast: PostV1AccountBodyAppearanceContrast | Unset = UNSET
    text_size: PostV1AccountBodyAppearanceTextSize | Unset = UNSET
    spacing: PostV1AccountBodyAppearanceSpacing | Unset = UNSET
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
        color_mode: PostV1AccountBodyAppearanceColorMode | Unset
        if isinstance(_color_mode, Unset):
            color_mode = UNSET
        else:
            color_mode = PostV1AccountBodyAppearanceColorMode(_color_mode)

        _reduce_motion = d.pop("reduce_motion", UNSET)
        reduce_motion: PostV1AccountBodyAppearanceReduceMotion | Unset
        if isinstance(_reduce_motion, Unset):
            reduce_motion = UNSET
        else:
            reduce_motion = PostV1AccountBodyAppearanceReduceMotion(_reduce_motion)

        _contrast = d.pop("contrast", UNSET)
        contrast: PostV1AccountBodyAppearanceContrast | Unset
        if isinstance(_contrast, Unset):
            contrast = UNSET
        else:
            contrast = PostV1AccountBodyAppearanceContrast(_contrast)

        _text_size = d.pop("text_size", UNSET)
        text_size: PostV1AccountBodyAppearanceTextSize | Unset
        if isinstance(_text_size, Unset):
            text_size = UNSET
        else:
            text_size = PostV1AccountBodyAppearanceTextSize(_text_size)

        _spacing = d.pop("spacing", UNSET)
        spacing: PostV1AccountBodyAppearanceSpacing | Unset
        if isinstance(_spacing, Unset):
            spacing = UNSET
        else:
            spacing = PostV1AccountBodyAppearanceSpacing(_spacing)

        focus_outlines = d.pop("focus_outlines", UNSET)

        underline_links = d.pop("underline_links", UNSET)

        post_v1_account_body_appearance = cls(
            color_mode=color_mode,
            reduce_motion=reduce_motion,
            contrast=contrast,
            text_size=text_size,
            spacing=spacing,
            focus_outlines=focus_outlines,
            underline_links=underline_links,
        )

        post_v1_account_body_appearance.additional_properties = d
        return post_v1_account_body_appearance

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
