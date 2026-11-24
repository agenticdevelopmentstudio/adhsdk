from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1ProcessingNodesByIdLogsResponse202")


@_attrs_define
class PostV1ProcessingNodesByIdLogsResponse202:
    """
    Attributes:
        accepted (int):
        dropped (int):
        object_ (Literal['log'] | Unset):
    """

    accepted: int
    dropped: int
    object_: Literal["log"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        accepted = self.accepted

        dropped = self.dropped

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "accepted": accepted,
                "dropped": dropped,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        accepted = d.pop("accepted")

        dropped = d.pop("dropped")

        object_ = cast(Literal["log"] | Unset, d.pop("object", UNSET))
        if object_ != "log" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'log', got '{object_}'")

        post_v1_processing_nodes_by_id_logs_response_202 = cls(
            accepted=accepted,
            dropped=dropped,
            object_=object_,
        )

        post_v1_processing_nodes_by_id_logs_response_202.additional_properties = d
        return post_v1_processing_nodes_by_id_logs_response_202

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
