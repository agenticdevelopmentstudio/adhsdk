from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.dm_chat_summary import DmChatSummary


T = TypeVar("T", bound="DmChatList")


@_attrs_define
class DmChatList:
    """
    Attributes:
        chats (list[DmChatSummary]):
        total (int):
        page (int):
        page_size (int):
    """

    chats: list[DmChatSummary]
    total: int
    page: int
    page_size: int
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        chats = []
        for chats_item_data in self.chats:
            chats_item = chats_item_data.to_dict()
            chats.append(chats_item)

        total = self.total

        page = self.page

        page_size = self.page_size

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "chats": chats,
                "total": total,
                "page": page,
                "pageSize": page_size,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.dm_chat_summary import DmChatSummary

        d = dict(src_dict)
        chats = []
        _chats = d.pop("chats")
        for chats_item_data in _chats:
            chats_item = DmChatSummary.from_dict(chats_item_data)

            chats.append(chats_item)

        total = d.pop("total")

        page = d.pop("page")

        page_size = d.pop("pageSize")

        dm_chat_list = cls(
            chats=chats,
            total=total,
            page=page,
            page_size=page_size,
        )

        dm_chat_list.additional_properties = d
        return dm_chat_list

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
