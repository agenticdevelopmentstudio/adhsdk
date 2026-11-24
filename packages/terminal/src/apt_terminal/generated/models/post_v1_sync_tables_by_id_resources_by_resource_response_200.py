from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.sync_enrollment_row import SyncEnrollmentRow


T = TypeVar("T", bound="PostV1SyncTablesByIdResourcesByResourceResponse200")


@_attrs_define
class PostV1SyncTablesByIdResourcesByResourceResponse200:
    """
    Attributes:
        tables (list[SyncEnrollmentRow]):
        object_ (Literal['resource'] | Unset):
    """

    tables: list[SyncEnrollmentRow]
    object_: Literal["resource"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        tables = []
        for tables_item_data in self.tables:
            tables_item = tables_item_data.to_dict()
            tables.append(tables_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "tables": tables,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.sync_enrollment_row import SyncEnrollmentRow

        d = dict(src_dict)
        tables = []
        _tables = d.pop("tables")
        for tables_item_data in _tables:
            tables_item = SyncEnrollmentRow.from_dict(tables_item_data)

            tables.append(tables_item)

        object_ = cast(Literal["resource"] | Unset, d.pop("object", UNSET))
        if object_ != "resource" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'resource', got '{object_}'")

        post_v1_sync_tables_by_id_resources_by_resource_response_200 = cls(
            tables=tables,
            object_=object_,
        )

        post_v1_sync_tables_by_id_resources_by_resource_response_200.additional_properties = d
        return post_v1_sync_tables_by_id_resources_by_resource_response_200

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
