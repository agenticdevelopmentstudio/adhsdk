from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.registry_field_def_type import RegistryFieldDefType
from ..models.registry_field_def_visibility import RegistryFieldDefVisibility
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.registry_field_def_config import RegistryFieldDefConfig
    from ..models.registry_field_def_show_if_type_0 import RegistryFieldDefShowIfType0


T = TypeVar("T", bound="RegistryFieldDef")


@_attrs_define
class RegistryFieldDef:
    """
    Attributes:
        id (str):
        ecosystem_id (str):
        registry_id (str):
        section_id (str):
        key (str): IMMUTABLE — the key under which values are stored in entries.values
        type_ (RegistryFieldDefType): IMMUTABLE — a member of the field-type catalog (vendor/registry-types.ts)
        label (str):
        help_ (str):
        required (bool):
        sort_order (int):
        config (RegistryFieldDefConfig): per-type config: select options, min/max, accepted image types
        visibility (RegistryFieldDefVisibility): The owner's CEILING for this field across every entry, widest first:
            'public' = anyone including a crawler; 'authenticated' = any signed-in hub member; 'private' = the entry's owner
            and the registry's owner only. A registrant may TIGHTEN it on their own entry (`valueVisibility` on the entry
            write) but never loosen it, so the value here is an upper bound on what any entry publishes — not necessarily
            what a given entry does.
        created (int): Unix timestamp, in seconds.
        updated (int): Unix timestamp, in seconds.
        sync_version (int):
        show_if (None | RegistryFieldDefShowIfType0 | Unset): a declarative visibility rule, evaluated fail-open
            (evaluateShowIf)
        deleted_at (None | str | Unset):
    """

    id: str
    ecosystem_id: str
    registry_id: str
    section_id: str
    key: str
    type_: RegistryFieldDefType
    label: str
    help_: str
    required: bool
    sort_order: int
    config: RegistryFieldDefConfig
    visibility: RegistryFieldDefVisibility
    created: int
    updated: int
    sync_version: int
    show_if: None | RegistryFieldDefShowIfType0 | Unset = UNSET
    deleted_at: None | str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.registry_field_def_show_if_type_0 import RegistryFieldDefShowIfType0

        id = self.id

        ecosystem_id = self.ecosystem_id

        registry_id = self.registry_id

        section_id = self.section_id

        key = self.key

        type_ = self.type_.value

        label = self.label

        help_ = self.help_

        required = self.required

        sort_order = self.sort_order

        config = self.config.to_dict()

        visibility = self.visibility.value

        created = self.created

        updated = self.updated

        sync_version = self.sync_version

        show_if: dict[str, Any] | None | Unset
        if isinstance(self.show_if, Unset):
            show_if = UNSET
        elif isinstance(self.show_if, RegistryFieldDefShowIfType0):
            show_if = self.show_if.to_dict()
        else:
            show_if = self.show_if

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
                "ecosystem_id": ecosystem_id,
                "registry_id": registry_id,
                "section_id": section_id,
                "key": key,
                "type": type_,
                "label": label,
                "help": help_,
                "required": required,
                "sort_order": sort_order,
                "config": config,
                "visibility": visibility,
                "created": created,
                "updated": updated,
                "sync_version": sync_version,
            }
        )
        if show_if is not UNSET:
            field_dict["show_if"] = show_if
        if deleted_at is not UNSET:
            field_dict["deleted_at"] = deleted_at

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.registry_field_def_config import RegistryFieldDefConfig
        from ..models.registry_field_def_show_if_type_0 import (
            RegistryFieldDefShowIfType0,
        )

        d = dict(src_dict)
        id = d.pop("id")

        ecosystem_id = d.pop("ecosystem_id")

        registry_id = d.pop("registry_id")

        section_id = d.pop("section_id")

        key = d.pop("key")

        type_ = RegistryFieldDefType(d.pop("type"))

        label = d.pop("label")

        help_ = d.pop("help")

        required = d.pop("required")

        sort_order = d.pop("sort_order")

        config = RegistryFieldDefConfig.from_dict(d.pop("config"))

        visibility = RegistryFieldDefVisibility(d.pop("visibility"))

        created = d.pop("created")

        updated = d.pop("updated")

        sync_version = d.pop("sync_version")

        def _parse_show_if(data: object) -> None | RegistryFieldDefShowIfType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                show_if_type_0 = RegistryFieldDefShowIfType0.from_dict(data)

                return show_if_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | RegistryFieldDefShowIfType0 | Unset, data)

        show_if = _parse_show_if(d.pop("show_if", UNSET))

        def _parse_deleted_at(data: object) -> None | str | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            return cast(None | str | Unset, data)

        deleted_at = _parse_deleted_at(d.pop("deleted_at", UNSET))

        registry_field_def = cls(
            id=id,
            ecosystem_id=ecosystem_id,
            registry_id=registry_id,
            section_id=section_id,
            key=key,
            type_=type_,
            label=label,
            help_=help_,
            required=required,
            sort_order=sort_order,
            config=config,
            visibility=visibility,
            created=created,
            updated=updated,
            sync_version=sync_version,
            show_if=show_if,
            deleted_at=deleted_at,
        )

        registry_field_def.additional_properties = d
        return registry_field_def

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
