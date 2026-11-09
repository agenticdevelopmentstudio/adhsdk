from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="PostV1ReservedIdentifiersReleaseBodyNewNames")


@_attrs_define
class PostV1ReservedIdentifiersReleaseBodyNewNames:
    """The name to give each dead row that is still sitting on its own slug, keyed by the held rdid — an entry per listed
    row whose `needsName` is true, including held descendants, since releasing a namespace releases the names inside it.
    A missing entry answers 409 naming the rdid it wants. A value that is not a legal segment, or that ends in what
    looks like a slice of an id, answers 400: an rdid is a name a person reads.

    """

    additional_properties: dict[str, str] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        post_v1_reserved_identifiers_release_body_new_names = cls()

        post_v1_reserved_identifiers_release_body_new_names.additional_properties = d
        return post_v1_reserved_identifiers_release_body_new_names

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> str:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: str) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
