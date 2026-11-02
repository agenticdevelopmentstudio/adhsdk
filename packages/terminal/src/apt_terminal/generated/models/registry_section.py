from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="RegistrySection")


@_attrs_define
class RegistrySection:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        registry_id (str):
        key (str): unique within the registry; create-only — the update schema omits it, matching field_defs.key
        label (str):
        description (str):
        sort_order (int):
        created_at (str):
        updated_at (str):
        sync_version (int):
        deleted_at (None | str | Unset):
    """

    id: str
    ecosystem_id: str
    registry_id: str
    key: str
    label: str
    description: str
    sort_order: int
    created_at: str
    updated_at: str
    sync_version: int
    deleted_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = self.id

        ecosystem_id = self.ecosystem_id

        registry_id = self.registry_id

        key = self.key

        label = self.label

        description = self.description

        sort_order = self.sort_order

        created_at = self.created_at

        updated_at = self.updated_at

        sync_version = self.sync_version

        deleted_at: None | str | Unset
        if isinstance(self.deleted_at, Unset):
            deleted_at = UNSET
        else:
            deleted_at = self.deleted_at

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "ecosystemId": ecosystem_id,
                "registryId": registry_id,
                "key": key,
                "label": label,
                "description": description,
                "sortOrder": sort_order,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "syncVersion": sync_version,
            }
        )
        if deleted_at is not UNSET:
            field_dict["deletedAt"] = deleted_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystemId")

        registry_id = d.pop("registryId")

        key = d.pop("key")

        label = d.pop("label")

        description = d.pop("description")

        sort_order = d.pop("sortOrder")

        created_at = d.pop("createdAt")

        updated_at = d.pop("updatedAt")

        sync_version = d.pop("syncVersion")

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deletedAt", UNSET))

        registry_section = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            registry_id=registry_id,
            key=key,
            label=label,
            description=description,
            sort_order=sort_order,
            created_at=created_at,
            updated_at=updated_at,
            sync_version=sync_version,
            deleted_at=deleted_at,
        )

        registry_section.additional_properties = d
        return registry_section

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
