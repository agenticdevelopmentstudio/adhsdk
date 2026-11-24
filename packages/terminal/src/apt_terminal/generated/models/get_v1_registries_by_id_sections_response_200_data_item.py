from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1RegistriesByIdSectionsResponse200DataItem")


@_attrs_define
class GetV1RegistriesByIdSectionsResponse200DataItem:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        registry_id (str):
        key (str): unique within the registry; create-only — the update schema omits it, matching field_defs.key
        label (str):
        description (str):
        sort_order (int):
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        deleted_at (None | str | Unset):
        object_ (Literal['section'] | Unset):
    """

    id: str
    ecosystem_id: str
    registry_id: str
    key: str
    label: str
    description: str
    sort_order: int
    created: int
    updated: int
    sync_version: int
    deleted_at: None | str | Unset = UNSET
    object_: Literal["section"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        registry_id = self.registry_id

        key = self.key

        label = self.label

        description = self.description

        sort_order = self.sort_order

        created = self.created

        updated = self.updated

        sync_version = self.sync_version

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystem_id": ecosystem_id,
                "registry_id": registry_id,
                "key": key,
                "label": label,
                "description": description,
                "sort_order": sort_order,
                "created": created,
                "updated": updated,
                "sync_version": sync_version,
            }
        )
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        registry_id = d.pop("registry_id")

        key = d.pop("key")

        label = d.pop("label")

        description = d.pop("description")

        sort_order = d.pop("sort_order")

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        object_ = cast(Literal["section"] | Unset, d.pop("object", UNSET))
        if object_ != "section" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'section', got '{object_}'")

        get_v1_registries_by_id_sections_response_200_data_item = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            registry_id=registry_id,
            key=key,
            label=label,
            description=description,
            sort_order=sort_order,
            created=created,
            updated=updated,
            sync_version=sync_version,
            deleted_at=deleted_at,
            object_=object_,
        )

        get_v1_registries_by_id_sections_response_200_data_item.additional_properties = d
        return get_v1_registries_by_id_sections_response_200_data_item

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
