from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar

from attrs import define as _attrs_define

from ..types import UNSET, Unset

T = TypeVar("T", bound="AiProcessingWorkerUsage")


@_attrs_define
class AiProcessingWorkerUsage:
    """
    Attributes:
        provider (str): The provider billed, as its API host (e.g. api.openai.com, localhost:11434)
        model (str): Model id
        input_tokens (int):
        output_tokens (int):
        cache_read_tokens (int | Unset):
        cache_write_tokens (int | Unset):
        reasoning_tokens (int | Unset):
        attempt (int | Unset): 1-based; default 1
        partial (bool | Unset): The call did not run to its end; with no tokens at all, the spend is unknown (unpriced)
    """

    provider: str
    model: str
    input_tokens: int
    output_tokens: int
    cache_read_tokens: int | Unset = UNSET
    cache_write_tokens: int | Unset = UNSET
    reasoning_tokens: int | Unset = UNSET
    attempt: int | Unset = UNSET
    partial: bool | Unset = UNSET

    def to_dict(self) -> dict[str, Any]:
        provider = self.provider

        model = self.model

        input_tokens = self.input_tokens

        output_tokens = self.output_tokens

        cache_read_tokens = self.cache_read_tokens

        cache_write_tokens = self.cache_write_tokens

        reasoning_tokens = self.reasoning_tokens

        attempt = self.attempt

        partial = self.partial

        field_dict: dict[str, Any] = {}

        field_dict.update(
            {
                "provider": provider,
                "model": model,
                "inputTokens": input_tokens,
                "outputTokens": output_tokens,
            }
        )
        if cache_read_tokens is not UNSET:
            field_dict["cacheReadTokens"] = cache_read_tokens
        if cache_write_tokens is not UNSET:
            field_dict["cacheWriteTokens"] = cache_write_tokens
        if reasoning_tokens is not UNSET:
            field_dict["reasoningTokens"] = reasoning_tokens
        if attempt is not UNSET:
            field_dict["attempt"] = attempt
        if partial is not UNSET:
            field_dict["partial"] = partial

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        provider = d.pop("provider")

        model = d.pop("model")

        input_tokens = d.pop("inputTokens")

        output_tokens = d.pop("outputTokens")

        cache_read_tokens = d.pop("cacheReadTokens", UNSET)

        cache_write_tokens = d.pop("cacheWriteTokens", UNSET)

        reasoning_tokens = d.pop("reasoningTokens", UNSET)

        attempt = d.pop("attempt", UNSET)

        partial = d.pop("partial", UNSET)

        ai_processing_worker_usage = cls(
            provider=provider,
            model=model,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            cache_read_tokens=cache_read_tokens,
            cache_write_tokens=cache_write_tokens,
            reasoning_tokens=reasoning_tokens,
            attempt=attempt,
            partial=partial,
        )

        return ai_processing_worker_usage
