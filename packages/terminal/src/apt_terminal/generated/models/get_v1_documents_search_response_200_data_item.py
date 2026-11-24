from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1DocumentsSearchResponse200DataItem")


@_attrs_define
class GetV1DocumentsSearchResponse200DataItem:
    """
    Attributes:
        block_id (str):
        document_id (str):
        block_type (str):
        position (str):
        snippet (str): Plain-text excerpt (ts_headline, no markup)
        rank (float): ts_rank relevance score
        object_ (Literal['document'] | Unset):
    """

    block_id: str
    document_id: str
    block_type: str
    position: str
    snippet: str
    rank: float
    object_: Literal["document"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        block_id = self.block_id

        document_id = self.document_id

        block_type = self.block_type

        position = self.position

        snippet = self.snippet

        rank = self.rank

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "block_id": block_id,
                "document_id": document_id,
                "block_type": block_type,
                "position": position,
                "snippet": snippet,
                "rank": rank,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        block_id = d.pop("block_id")

        document_id = d.pop("document_id")

        block_type = d.pop("block_type")

        position = d.pop("position")

        snippet = d.pop("snippet")

        rank = d.pop("rank")

        object_ = cast(Literal["document"] | Unset, d.pop("object", UNSET))
        if object_ != "document" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'document', got '{object_}'")

        get_v1_documents_search_response_200_data_item = cls(
            block_id=block_id,
            document_id=document_id,
            block_type=block_type,
            position=position,
            snippet=snippet,
            rank=rank,
            object_=object_,
        )

        get_v1_documents_search_response_200_data_item.additional_properties = d
        return get_v1_documents_search_response_200_data_item

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
