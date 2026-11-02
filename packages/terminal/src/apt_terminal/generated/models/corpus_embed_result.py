from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="CorpusEmbedResult")


@_attrs_define
class CorpusEmbedResult:
    """
    Attributes:
        chunked (int): Documents (re)split into passages this call
        embedded (int): Passages embedded this call
        failed (int): Passages that failed to embed (retried by the next call)
        more (bool): True if a batch filled `limit`, i.e. work was left UNATTEMPTED — call again. Never true merely
            because passages failed, so a "while more" loop cannot spin forever on one permanently unembeddable passage.
    """

    chunked: int
    embedded: int
    failed: int
    more: bool
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        chunked = self.chunked

        embedded = self.embedded

        failed = self.failed

        more = self.more

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "chunked": chunked,
                "embedded": embedded,
                "failed": failed,
                "more": more,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        chunked = d.pop("chunked")

        embedded = d.pop("embedded")

        failed = d.pop("failed")

        more = d.pop("more")

        corpus_embed_result = cls(
            chunked=chunked,
            embedded=embedded,
            failed=failed,
            more=more,
        )

        corpus_embed_result.additional_properties = d
        return corpus_embed_result

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
