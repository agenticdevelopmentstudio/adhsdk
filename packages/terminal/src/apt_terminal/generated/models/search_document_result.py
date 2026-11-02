from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="SearchDocumentResult")


@_attrs_define
class SearchDocumentResult:
    """
    Attributes:
        block_id (str):
        document_id (str):
        block_type (str):
        position (str):
        snippet (str): Plain-text excerpt (ts_headline, no markup)
        rank (float): ts_rank relevance score
    """

    block_id: str
    document_id: str
    block_type: str
    position: str
    snippet: str
    rank: float
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        block_id = self.block_id

        document_id = self.document_id

        block_type = self.block_type

        position = self.position

        snippet = self.snippet

        rank = self.rank

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "blockId": block_id,
                "documentId": document_id,
                "blockType": block_type,
                "position": position,
                "snippet": snippet,
                "rank": rank,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        block_id = d.pop("blockId")

        document_id = d.pop("documentId")

        block_type = d.pop("blockType")

        position = d.pop("position")

        snippet = d.pop("snippet")

        rank = d.pop("rank")

        search_document_result = cls(
            block_id=block_id,
            document_id=document_id,
            block_type=block_type,
            position=position,
            snippet=snippet,
            rank=rank,
        )

        search_document_result.additional_properties = d
        return search_document_result

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
