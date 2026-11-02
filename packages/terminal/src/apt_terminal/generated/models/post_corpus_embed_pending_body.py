from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostCorpusEmbedPendingBody")


@_attrs_define
class PostCorpusEmbedPendingBody:
    """
    Attributes:
        bucket_type_id (str):
        limit (int | Unset):
    """

    bucket_type_id: str
    limit: int | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        bucket_type_id = self.bucket_type_id

        limit = self.limit

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "bucketTypeId": bucket_type_id,
            }
        )
        if limit is not UNSET:
            field_dict["limit"] = limit

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        bucket_type_id = d.pop("bucketTypeId")

        limit = d.pop("limit", UNSET)

        post_corpus_embed_pending_body = cls(
            bucket_type_id=bucket_type_id,
            limit=limit,
        )

        post_corpus_embed_pending_body.additional_properties = d
        return post_corpus_embed_pending_body

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
