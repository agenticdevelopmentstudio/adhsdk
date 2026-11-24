from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.sync_change import SyncChange
    from ..models.sync_manifest_entry import SyncManifestEntry


T = TypeVar("T", bound="GetV1SyncPullResponse200")


@_attrs_define
class GetV1SyncPullResponse200:
    """
    Attributes:
        manifest (list[SyncManifestEntry]):
        changes (list[SyncChange]):
        cursor (str): Opaque; echo back on the next pull
        has_more (bool):
        object_ (Literal['sync.pull'] | Unset):
    """

    manifest: list[SyncManifestEntry]
    changes: list[SyncChange]
    cursor: str
    has_more: bool
    object_: Literal["sync.pull"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        manifest = []
        for manifest_item_data in self.manifest:
            manifest_item = manifest_item_data.to_dict()
            manifest.append(manifest_item)

        changes = []
        for changes_item_data in self.changes:
            changes_item = changes_item_data.to_dict()
            changes.append(changes_item)

        cursor = self.cursor

        has_more = self.has_more

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "manifest": manifest,
                "changes": changes,
                "cursor": cursor,
                "has_more": has_more,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.sync_change import SyncChange
        from ..models.sync_manifest_entry import SyncManifestEntry

        d = dict(src_dict)
        manifest = []
        _manifest = d.pop("manifest")
        for manifest_item_data in _manifest:
            manifest_item = SyncManifestEntry.from_dict(manifest_item_data)

            manifest.append(manifest_item)

        changes = []
        _changes = d.pop("changes")
        for changes_item_data in _changes:
            changes_item = SyncChange.from_dict(changes_item_data)

            changes.append(changes_item)

        cursor = d.pop("cursor")

        has_more = d.pop("has_more")

        object_ = cast(Literal["sync.pull"] | Unset, d.pop("object", UNSET))
        if object_ != "sync.pull" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'sync.pull', got '{object_}'")

        get_v1_sync_pull_response_200 = cls(
            manifest=manifest,
            changes=changes,
            cursor=cursor,
            has_more=has_more,
            object_=object_,
        )

        get_v1_sync_pull_response_200.additional_properties = d
        return get_v1_sync_pull_response_200

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
