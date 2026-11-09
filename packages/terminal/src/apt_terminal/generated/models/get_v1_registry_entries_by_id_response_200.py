from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.public_registry_entry_detail import PublicRegistryEntryDetail
    from ..models.public_registry_entry_response_json_ld import PublicRegistryEntryResponseJsonLd
    from ..models.public_registry_entry_response_registry import PublicRegistryEntryResponseRegistry


T = TypeVar("T", bound="GetV1RegistryEntriesByIdResponse200")


@_attrs_define
class GetV1RegistryEntriesByIdResponse200:
    """
    Attributes:
        registry (PublicRegistryEntryResponseRegistry):
        entry (PublicRegistryEntryDetail):
        json_ld (PublicRegistryEntryResponseJsonLd): schema.org markup from entryJsonLd, including a resolved url — the
            route derives the entry's canonical base (host AND path prefix) from the backend's vendored sites registry
            (publicEntryBaseFor) before building this object, so the page only needs to place it verbatim in a <script
            type="application/ld+json"> tag.
        object_ (Literal['registry_entry'] | Unset):
    """

    registry: PublicRegistryEntryResponseRegistry
    entry: PublicRegistryEntryDetail
    json_ld: PublicRegistryEntryResponseJsonLd
    object_: Literal["registry_entry"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        registry = self.registry.to_dict()

        entry = self.entry.to_dict()

        json_ld = self.json_ld.to_dict()

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "registry": registry,
                "entry": entry,
                "json_ld": json_ld,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.public_registry_entry_detail import PublicRegistryEntryDetail
        from ..models.public_registry_entry_response_json_ld import (
            PublicRegistryEntryResponseJsonLd,
        )
        from ..models.public_registry_entry_response_registry import (
            PublicRegistryEntryResponseRegistry,
        )

        d = dict(src_dict)
        registry = PublicRegistryEntryResponseRegistry.from_dict(d.pop("registry"))

        entry = PublicRegistryEntryDetail.from_dict(d.pop("entry"))

        json_ld = PublicRegistryEntryResponseJsonLd.from_dict(d.pop("json_ld"))

        object_ = cast(Literal["registry_entry"] | Unset, d.pop("object", UNSET))
        if object_ != "registry_entry" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'registry_entry', got '{object_}'")

        get_v1_registry_entries_by_id_response_200 = cls(
            registry=registry,
            entry=entry,
            json_ld=json_ld,
            object_=object_,
        )

        get_v1_registry_entries_by_id_response_200.additional_properties = d
        return get_v1_registry_entries_by_id_response_200

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
