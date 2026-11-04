from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

T = TypeVar("T", bound="UsageLlmTokens")


@_attrs_define
class UsageLlmTokens:
    """
    Attributes:
        input_ (float):
        output (float): All output, reasoning included
        cache_read (float):
        cache_write (float):
        reasoning (float):
    """

    input_: float
    output: float
    cache_read: float
    cache_write: float
    reasoning: float
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        input_ = self.input_

        output = self.output

        cache_read = self.cache_read

        cache_write = self.cache_write

        reasoning = self.reasoning

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "input": input_,
                "output": output,
                "cacheRead": cache_read,
                "cacheWrite": cache_write,
                "reasoning": reasoning,
            }
        )

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        input_ = d.pop("input")

        output = d.pop("output")

        cache_read = d.pop("cacheRead")

        cache_write = d.pop("cacheWrite")

        reasoning = d.pop("reasoning")

        usage_llm_tokens = cls(
            input_=input_,
            output=output,
            cache_read=cache_read,
            cache_write=cache_write,
            reasoning=reasoning,
        )

        usage_llm_tokens.additional_properties = d
        return usage_llm_tokens

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
