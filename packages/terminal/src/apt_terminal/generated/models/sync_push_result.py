from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.sync_push_result_status import SyncPushResultStatus
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.sync_push_result_current_type_0 import SyncPushResultCurrentType0


T = TypeVar("T", bound="SyncPushResult")


@_attrs_define
class SyncPushResult:
    """
    Attributes:
        op_id (UUID):
        status (SyncPushResultStatus):
        reason (str | Unset):
        current (None | SyncPushResultCurrentType0 | Unset):
        new_version (str | Unset): Post-apply sync_version; present only on `applied` results that wrote a row (absent
            for an idempotent no-op delete). Clients SHOULD adopt it as the row's new baseVersion for subsequent staged
            edits.
    """

    op_id: UUID
    status: SyncPushResultStatus
    reason: str | Unset = UNSET
    current: None | SyncPushResultCurrentType0 | Unset = UNSET
    new_version: str | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        from ..models.sync_push_result_current_type_0 import (
            SyncPushResultCurrentType0,
        )

        op_id = str(self.op_id)

        status = self.status.value

        reason = self.reason

        current: dict[str, Any] | None | Unset
        if isinstance(self.current, Unset):
            current = UNSET
        elif isinstance(self.current, SyncPushResultCurrentType0):
            current = self.current.to_dict()
        else:
            current = self.current

        new_version = self.new_version

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "opId": op_id,
                "status": status,
            }
        )
        if reason is not UNSET:
            field_dict["reason"] = reason
        if current is not UNSET:
            field_dict["current"] = current
        if new_version is not UNSET:
            field_dict["newVersion"] = new_version

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.sync_push_result_current_type_0 import (
            SyncPushResultCurrentType0,
        )

        d = dict(src_dict)
        op_id = UUID(d.pop("opId"))

        status = SyncPushResultStatus(d.pop("status"))

        reason = d.pop("reason", UNSET)

        def _parse_current(data: object) -> None | SyncPushResultCurrentType0 | Unset:
            if data is None:
                return data
            if isinstance(data, Unset):
                return data
            try:
                if not isinstance(data, dict):
                    raise TypeError()
                current_type_0 = SyncPushResultCurrentType0.from_dict(data)

                return current_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | SyncPushResultCurrentType0 | Unset, data)

        current = _parse_current(d.pop("current", UNSET))

        new_version = d.pop("newVersion", UNSET)

        sync_push_result = cls(
            op_id=op_id,
            status=status,
            reason=reason,
            current=current,
            new_version=new_version,
        )

        sync_push_result.additional_properties = d
        return sync_push_result

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
