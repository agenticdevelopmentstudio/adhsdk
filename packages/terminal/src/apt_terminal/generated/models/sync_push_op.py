from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.sync_push_op_type import SyncPushOpType
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.sync_push_op_data import SyncPushOpData


T = TypeVar("T", bound="SyncPushOp")


@_attrs_define
class SyncPushOp:
    """
    Attributes:
        op_id (UUID): Client-generated UUIDv7 idempotency key
        resource (str):
        row_id (UUID): Client-generated row id (offline creation)
        type_ (SyncPushOpType):
        base_version (str | Unset): sync_version the client last saw; stale → conflict
        data (SyncPushOpData | Unset):
    """

    op_id: UUID
    resource: str
    row_id: UUID
    type_: SyncPushOpType
    base_version: str | Unset = UNSET
    data: SyncPushOpData | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        op_id = str(self.op_id)

        resource = self.resource

        row_id = str(self.row_id)

        type_ = self.type_.value

        base_version = self.base_version

        data: dict[str, Any] | Unset = UNSET
        if not isinstance(self.data, Unset):
            data = self.data.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "opId": op_id,
                "resource": resource,
                "rowId": row_id,
                "type": type_,
            }
        )
        if base_version is not UNSET:
            field_dict["baseVersion"] = base_version
        if data is not UNSET:
            field_dict["data"] = data

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.sync_push_op_data import SyncPushOpData

        d = dict(src_dict)
        op_id = UUID(d.pop("opId"))

        resource = d.pop("resource")

        row_id = UUID(d.pop("rowId"))

        type_ = SyncPushOpType(d.pop("type"))

        base_version = d.pop("baseVersion", UNSET)

        _data = d.pop("data", UNSET)
        data: SyncPushOpData | Unset
        if isinstance(_data, Unset):
            data = UNSET
        else:
            data = SyncPushOpData.from_dict(_data)

        sync_push_op = cls(
            op_id=op_id,
            resource=resource,
            row_id=row_id,
            type_=type_,
            base_version=base_version,
            data=data,
        )

        sync_push_op.additional_properties = d
        return sync_push_op

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
