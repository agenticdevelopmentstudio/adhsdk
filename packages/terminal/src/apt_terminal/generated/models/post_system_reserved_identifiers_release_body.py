from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_system_reserved_identifiers_release_body_new_names import (
        PostSystemReservedIdentifiersReleaseBodyNewNames,
    )


T = TypeVar("T", bound="PostSystemReservedIdentifiersReleaseBody")


@_attrs_define
class PostSystemReservedIdentifiersReleaseBody:
    """
    Attributes:
        rdid (str): The held identifier, exactly as listed
        entity_type (str): Verified against the stored mapping
        entity_id (str): Verified against the stored mapping
        new_names (PostSystemReservedIdentifiersReleaseBodyNewNames | Unset): The name to give each dead row that is
            still sitting on its own slug, keyed by the held rdid — an entry per listed row whose `needsName` is true,
            including held descendants, since releasing a namespace releases the names inside it. A missing entry answers
            409 naming the rdid it wants. A value that is not a legal segment, or that ends in what looks like a slice of an
            id, answers 400: an rdid is a name a person reads.
    """

    rdid: str
    entity_type: str
    entity_id: str
    new_names: PostSystemReservedIdentifiersReleaseBodyNewNames | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        rdid = self.rdid

        entity_type = self.entity_type

        entity_id = self.entity_id

        new_names: dict[str, Any] | Unset = UNSET
        if not isinstance(self.new_names, Unset):
            new_names = self.new_names.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "rdid": rdid,
                "entityType": entity_type,
                "entityId": entity_id,
            }
        )
        if new_names is not UNSET:
            field_dict["newNames"] = new_names

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_system_reserved_identifiers_release_body_new_names import (
            PostSystemReservedIdentifiersReleaseBodyNewNames,
        )

        d = dict(src_dict)
        rdid = d.pop("rdid")

        entity_type = d.pop("entityType")

        entity_id = d.pop("entityId")

        _new_names = d.pop("newNames", UNSET)
        new_names: PostSystemReservedIdentifiersReleaseBodyNewNames | Unset
        if isinstance(_new_names, Unset):
            new_names = UNSET
        else:
            new_names = PostSystemReservedIdentifiersReleaseBodyNewNames.from_dict(_new_names)

        post_system_reserved_identifiers_release_body = cls(
            rdid=rdid,
            entity_type=entity_type,
            entity_id=entity_id,
            new_names=new_names,
        )

        post_system_reserved_identifiers_release_body.additional_properties = d
        return post_system_reserved_identifiers_release_body

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
