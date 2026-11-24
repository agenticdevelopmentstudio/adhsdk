from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.sync_enrollment_row_push_mode import SyncEnrollmentRowPushMode
from ..models.sync_enrollment_row_scope import SyncEnrollmentRowScope
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1SyncTablesByIdResponse200DataItem")


@_attrs_define
class GetV1SyncTablesByIdResponse200DataItem:
    """
    Attributes:
        resource (str): "<schema>.<table>", e.g. content.contacts
        scope (SyncEnrollmentRowScope): Which rows a caller syncs: 'owner' the rows whose owner pair names them,
            'author' the rows whose author pair does, 'ecosystem' every row in their ecosystem
        push_mode (SyncEnrollmentRowPushMode): 'route' means /sync/push refuses direct writes; the row's own route owns
            them
        default_enabled (bool): What the shipped catalog says
        enabled (bool): What is actually in force — the override if there is one
        overridden (bool):
        object_ (Literal['sync.table'] | Unset):
    """

    resource: str
    scope: SyncEnrollmentRowScope
    push_mode: SyncEnrollmentRowPushMode
    default_enabled: bool
    enabled: bool
    overridden: bool
    object_: Literal["sync.table"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        resource = self.resource

        scope = self.scope.value

        push_mode = self.push_mode.value

        default_enabled = self.default_enabled

        enabled = self.enabled

        overridden = self.overridden

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "resource": resource,
                "scope": scope,
                "push_mode": push_mode,
                "default_enabled": default_enabled,
                "enabled": enabled,
                "overridden": overridden,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        resource = d.pop("resource")

        scope = SyncEnrollmentRowScope(d.pop("scope"))

        push_mode = SyncEnrollmentRowPushMode(d.pop("push_mode"))

        default_enabled = d.pop("default_enabled")

        enabled = d.pop("enabled")

        overridden = d.pop("overridden")

        object_ = cast(Literal["sync.table"] | Unset, d.pop("object", UNSET))
        if object_ != "sync.table" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'sync.table', got '{object_}'")

        get_v1_sync_tables_by_id_response_200_data_item = cls(
            resource=resource,
            scope=scope,
            push_mode=push_mode,
            default_enabled=default_enabled,
            enabled=enabled,
            overridden=overridden,
            object_=object_,
        )

        get_v1_sync_tables_by_id_response_200_data_item.additional_properties = d
        return get_v1_sync_tables_by_id_response_200_data_item

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
