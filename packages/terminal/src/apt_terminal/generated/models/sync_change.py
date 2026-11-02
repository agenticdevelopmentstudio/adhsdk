from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.sync_change_op import SyncChangeOp
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.sync_change_data import SyncChangeData


T = TypeVar("T", bound="SyncChange")


@_attrs_define
class SyncChange:
    """
    Attributes:
        resource (str):
        id (str):
        op (SyncChangeOp):
        sync_version (str): Server-assigned monotonic version (bigint as string)
        data (SyncChangeData | Unset): Full row for upserts; absent for deletes
    """

    resource: str
    id: str
    op: SyncChangeOp
    sync_version: str
    data: SyncChangeData | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        resource = self.resource

        id = self.id

        op = self.op.value

        sync_version = self.sync_version

        data: dict[str, Any] | Unset = UNSET
        if not isinstance(self.data, Unset):
            data = self.data.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "resource": resource,
                "id": id,
                "op": op,
                "syncVersion": sync_version,
            }
        )
        if data is not UNSET:
            field_dict["data"] = data

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.sync_change_data import SyncChangeData

        d = dict(src_dict)
        resource = d.pop("resource")

        id = d.pop("id")

        op = SyncChangeOp(d.pop("op"))

        sync_version = d.pop("syncVersion")

        _data = d.pop("data", UNSET)
        data: SyncChangeData | Unset
        if isinstance(_data, Unset):
            data = UNSET
        else:
            data = SyncChangeData.from_dict(_data)

        sync_change = cls(
            resource=resource,
            id=id,
            op=op,
            sync_version=sync_version,
            data=data,
        )

        sync_change.additional_properties = d
        return sync_change

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
