from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.access_audit_entry import AccessAuditEntry


T = TypeVar("T", bound="AccessAuditPage")


@_attrs_define
class AccessAuditPage:
    """
    Attributes:
        items (list[AccessAuditEntry]):
        page (int):
        page_size (int): Clamped 1..200
        total (int): Saturates at a 10,000-row count cap
    """

    items: list[AccessAuditEntry]
    page: int
    page_size: int
    total: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        items = []
        for items_item_data in self.items:
            items_item = items_item_data.to_dict()
            items.append(items_item)

        page = self.page

        page_size = self.page_size

        total = self.total

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "items": items,
                "page": page,
                "pageSize": page_size,
                "total": total,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.access_audit_entry import AccessAuditEntry

        d = dict(src_dict)
        items = []
        _items = d.pop("items")
        for items_item_data in _items:
            items_item = AccessAuditEntry.from_dict(items_item_data)

            items.append(items_item)

        page = d.pop("page")

        page_size = d.pop("pageSize")

        total = d.pop("total")

        access_audit_page = cls(
            items=items,
            page=page,
            page_size=page_size,
            total=total,
        )

        access_audit_page.additional_properties = d
        return access_audit_page

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
