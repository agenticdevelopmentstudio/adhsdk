from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.sync_enrollment_row_push_mode import SyncEnrollmentRowPushMode
from ..models.sync_enrollment_row_scope import SyncEnrollmentRowScope

T = TypeVar("T", bound="SyncEnrollmentRow")


@_attrs_define
class SyncEnrollmentRow:
    """One resource from the sync catalog as it stands for a given ecosystem: what the code ships as the default, and
    whether an operator has overridden it.

        Attributes:
            resource (str): "<schema>.<table>", e.g. content.contacts
            scope (SyncEnrollmentRowScope):
            push_mode (SyncEnrollmentRowPushMode): 'route' means /sync/push refuses direct writes; the row's own route owns
                them
            default_enabled (bool): What the shipped catalog says
            enabled (bool): What is actually in force — the override if there is one
            overridden (bool):
    """

    resource: str
    scope: SyncEnrollmentRowScope
    push_mode: SyncEnrollmentRowPushMode
    default_enabled: bool
    enabled: bool
    overridden: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        resource = self.resource

        scope = self.scope.value

        push_mode = self.push_mode.value

        default_enabled = self.default_enabled

        enabled = self.enabled

        overridden = self.overridden

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "resource": resource,
                "scope": scope,
                "pushMode": push_mode,
                "defaultEnabled": default_enabled,
                "enabled": enabled,
                "overridden": overridden,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        resource = d.pop("resource")

        scope = SyncEnrollmentRowScope(d.pop("scope"))

        push_mode = SyncEnrollmentRowPushMode(d.pop("pushMode"))

        default_enabled = d.pop("defaultEnabled")

        enabled = d.pop("enabled")

        overridden = d.pop("overridden")

        sync_enrollment_row = cls(
            resource=resource,
            scope=scope,
            push_mode=push_mode,
            default_enabled=default_enabled,
            enabled=enabled,
            overridden=overridden,
        )

        sync_enrollment_row.additional_properties = d
        return sync_enrollment_row

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
