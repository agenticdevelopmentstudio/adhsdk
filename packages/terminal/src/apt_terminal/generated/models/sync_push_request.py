from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.sync_push_op import SyncPushOp


T = TypeVar("T", bound="SyncPushRequest")


@_attrs_define
class SyncPushRequest:
    """
    Attributes:
        device_id (str):
        ops (list[SyncPushOp]):
    """

    device_id: str
    ops: list[SyncPushOp]
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        device_id = self.device_id

        ops = []
        for ops_item_data in self.ops:
            ops_item = ops_item_data.to_dict()
            ops.append(ops_item)

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "device_id": device_id,
                "ops": ops,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.sync_push_op import SyncPushOp

        d = dict(src_dict)
        device_id = d.pop("device_id")

        ops = []
        _ops = d.pop("ops")
        for ops_item_data in _ops:
            ops_item = SyncPushOp.from_dict(ops_item_data)

            ops.append(ops_item)

        sync_push_request = cls(
            device_id=device_id,
            ops=ops,
        )

        sync_push_request.additional_properties = d
        return sync_push_request

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
