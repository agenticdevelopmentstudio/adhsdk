from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

if TYPE_CHECKING:
    from ..models.ai_processing_node_log import AiProcessingNodeLog


T = TypeVar("T", bound="AiProcessingNodeLogPage")


@_attrs_define
class AiProcessingNodeLogPage:
    """
    Attributes:
        entries (list[AiProcessingNodeLog]):
        next_before (int | None): Pass as `before` for the next (older) page; null = no more
    """

    entries: list[AiProcessingNodeLog]
    next_before: int | None
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        entries = []
        for entries_item_data in self.entries:
            entries_item = entries_item_data.to_dict()
            entries.append(entries_item)

        next_before: int | None
        next_before = self.next_before

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "entries": entries,
                "next_before": next_before,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.ai_processing_node_log import AiProcessingNodeLog

        d = dict(src_dict)
        entries = []
        _entries = d.pop("entries")
        for entries_item_data in _entries:
            entries_item = AiProcessingNodeLog.from_dict(entries_item_data)

            entries.append(entries_item)

        def _parse_next_before(data: object) -> int | None:
            if data is None:
                return data
            return cast(int | None, data)

        next_before = _parse_next_before(d.pop("next_before"))

        ai_processing_node_log_page = cls(
            entries=entries,
            next_before=next_before,
        )

        ai_processing_node_log_page.additional_properties = d
        return ai_processing_node_log_page

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
