from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.post_v1_registry_entries_body_value_visibility_additional_property import (
    PostV1RegistryEntriesBodyValueVisibilityAdditionalProperty,
)

T = TypeVar("T", bound="PostV1RegistryEntriesBodyValueVisibility")


@_attrs_define
class PostV1RegistryEntriesBodyValueVisibility:
    """The registrant's per-field audience overrides on THIS entry, keyed by field_defs.key. Merge-patch like `values`: a
    key you omit keeps its stored setting, a key sent as null clears the override back to the def's setting. Each
    override may only TIGHTEN the owner's ceiling (RegistryFieldDef.visibility); asking for a WIDER one is a 400 naming
    the field, never a silent clamp — a 200 would leave the registrant believing they published a field the owner keeps
    private. A stored override the owner has since tightened past is clamped and written back without erroring, since it
    was already clamped on every read.

    """

    additional_properties: dict[str, PostV1RegistryEntriesBodyValueVisibilityAdditionalProperty] = (
        _attrs_field(init=False, factory=dict)
    )

    def to_dict(self) -> dict[str, Any]:
        field_dict: dict[str, Any] = {}
        for prop_name, prop in self.additional_properties.items():
            field_dict[prop_name] = prop.value

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        post_v1_registry_entries_body_value_visibility = cls()

        additional_properties = {}
        for prop_name, prop_dict in d.items():
            additional_property = PostV1RegistryEntriesBodyValueVisibilityAdditionalProperty(
                prop_dict
            )

            additional_properties[prop_name] = additional_property

        post_v1_registry_entries_body_value_visibility.additional_properties = additional_properties
        return post_v1_registry_entries_body_value_visibility

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> PostV1RegistryEntriesBodyValueVisibilityAdditionalProperty:
        return self.additional_properties[key]

    def __setitem__(
        self, key: str, value: PostV1RegistryEntriesBodyValueVisibilityAdditionalProperty
    ) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
