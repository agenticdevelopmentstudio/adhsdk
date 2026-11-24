from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.ai_processing_node_log import AiProcessingNodeLog


T = TypeVar("T", bound="GetV1ProcessingLogsResponse200")


@_attrs_define
class GetV1ProcessingLogsResponse200:
    """
    Attributes:
        entries (list[AiProcessingNodeLog]):
        next_before (int | None): Pass as `before` for the next (older) page; null = no more
        object_ (Literal['processing.log'] | Unset):
    """

    entries: list[AiProcessingNodeLog]
    next_before: int | None
    object_: Literal["processing.log"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        entries = []
        for entries_item_data in self.entries:
            entries_item = entries_item_data.to_dict()
            entries.append(entries_item)

        next_before: int | None
        next_before = self.next_before

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "entries": entries,
                "next_before": next_before,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

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

        object_ = cast(Literal["processing.log"] | Unset, d.pop("object", UNSET))
        if object_ != "processing.log" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'processing.log', got '{object_}'")

        get_v1_processing_logs_response_200 = cls(
            entries=entries,
            next_before=next_before,
            object_=object_,
        )

        get_v1_processing_logs_response_200.additional_properties = d
        return get_v1_processing_logs_response_200

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
